using Godot;
using MegaCrit.Sts2.Core.Combat;
using MegaCrit.Sts2.Core.Context;
using MegaCrit.Sts2.Core.Entities.Ascension;
using MegaCrit.Sts2.Core.Entities.Cards;
using MegaCrit.Sts2.Core.Entities.Creatures;
using MegaCrit.Sts2.Core.Entities.Merchant;
using MegaCrit.Sts2.Core.Helpers;
using MegaCrit.Sts2.Core.Hooks;
using MegaCrit.Sts2.Core.Models.Powers;
using MegaCrit.Sts2.Core.Models.Relics;
using MegaCrit.Sts2.Core.Nodes;
using MegaCrit.Sts2.Core.Nodes.Audio;
using MegaCrit.Sts2.Core.Multiplayer;
using MegaCrit.Sts2.Core.Rooms;
using MegaCrit.Sts2.Core.Runs;
using MegaCrit.Sts2.Core.Saves;

namespace ReactiveCompanionUI;

/// <summary>Connects the persistent visual scene to read-only game events.</summary>
public partial class CompanionBridge : Node
{
    public Control? Visual { get; set; }

    private Creature? _observedCreature;
    private CombatState? _combatState;
    private string _sceneState = "hidden";
    private double _reactionCooldown;
    private int _playerTurns;
    private bool _slAvailable;
    private bool _potionAvailable;
    private bool _jugglingAvailable;
    private bool _removalAvailable;
    private bool _slInProgress;
    private double _availabilityRefresh;
    private int _seenCardPlaysStarted;

    public override void _Ready()
    {
        Visual?.Connect("peek_requested", Callable.From(OnPeekRequested));
        Visual?.Connect("potion_odds_requested", Callable.From(OnPotionOddsRequested));
        Visual?.Connect("juggling_count_requested", Callable.From(OnJugglingCountRequested));
        Visual?.Connect("removal_price_requested", Callable.From(OnRemovalPriceRequested));
        Visual?.Connect("sl_requested", Callable.From(OnSlRequested));
        var combat = CombatManager.Instance;
        combat.History.Changed += OnHistoryChanged;
        combat.CombatBegan += OnCombatBegan;
        combat.CombatWon += OnCombatWon;
        combat.CombatEnded += OnCombatEnded;
        combat.TurnStarted += OnTurnStarted;
        SetProcess(true);
    }

    public override void _ExitTree()
    {
        DetachCreature();
        var combat = CombatManager.Instance;
        combat.History.Changed -= OnHistoryChanged;
        combat.CombatBegan -= OnCombatBegan;
        combat.CombatWon -= OnCombatWon;
        combat.CombatEnded -= OnCombatEnded;
        combat.TurnStarted -= OnTurnStarted;
    }

    public override void _Process(double delta)
    {
        if (Visual is null)
            return;

        _reactionCooldown = Math.Max(0, _reactionCooldown - delta);

        var game = NGame.Instance;
        var run = game?.CurrentRunNode;
        var sceneState = game?.MainMenu is not null
            ? "front"
            : run?.CombatRoom is not null
                ? "battle"
                : run is not null ? "front" : "hidden";

        _availabilityRefresh -= delta;
        if (_availabilityRefresh <= 0 || _sceneState != sceneState)
        {
            _availabilityRefresh = 0.25;
            var slAvailable = CanSl();
            if (_slAvailable != slAvailable)
            {
                _slAvailable = slAvailable;
                Visual.Call("set_sl_available", slAvailable);
            }

            var potionAvailable = sceneState == "battle" && _combatState is not null;
            if (_potionAvailable != potionAvailable)
            {
                _potionAvailable = potionAvailable;
                Visual.Call("set_potion_available", potionAvailable);
            }

            var jugglingAvailable = sceneState == "battle" && _combatState is not null
                && _observedCreature?.HasPower<JugglingPower>() == true;
            if (_jugglingAvailable != jugglingAvailable)
            {
                _jugglingAvailable = jugglingAvailable;
                Visual.Call("set_juggling_available", jugglingAvailable);
            }

            var removalAvailable = run is not null
                && game?.MainMenu is null && RunManager.Instance.IsInProgress
                && !RunManager.Instance.IsCleaningUp;
            if (_removalAvailable != removalAvailable)
            {
                _removalAvailable = removalAvailable;
                Visual.Call("set_removal_available", removalAvailable);
            }
        }

        if (_sceneState == sceneState)
            return;

        _sceneState = sceneState;
        Visual.Visible = sceneState != "hidden";
        if (sceneState == "hidden")
        {
            DetachCreature();
            return;
        }

        Visual.Call("set_pose", sceneState);
    }

    private void OnCombatBegan(CombatState state)
    {
        DetachCreature();
        _combatState = state;
        _seenCardPlaysStarted = CombatManager.Instance.History.CardPlaysStarted.Count();
        _playerTurns = 0;
        try
        {
            _observedCreature = LocalContext.GetMe(state)?.Creature;
            if (_observedCreature is not null)
                _observedCreature.CurrentHpChanged += OnHealthChanged;
        }
        catch (InvalidOperationException)
        {
            // A local player may not exist while joining or replaying a run.
        }

        React("thinking", "先看看对面的意图。", urgent: true);
    }

    private void OnCombatWon(CombatRoom _)
    {
        React("happy", "做到了，辛苦啦！", urgent: true);
    }

    private void OnCombatEnded(CombatRoom _)
    {
        DetachCreature();
        _combatState = null;
        SetJugglingAvailable(false);
    }

    private void OnHistoryChanged()
    {
        var plays = CombatManager.Instance.History.CardPlaysStarted.ToList();
        if (plays.Count < _seenCardPlaysStarted)
            _seenCardPlaysStarted = 0;

        var firstNewPlay = _seenCardPlaysStarted;
        _seenCardPlaysStarted = plays.Count;
        if (_combatState is null || _observedCreature?.HasPower<JugglingPower>() != true)
            return;

        SetJugglingAvailable(true);
        for (var i = firstNewPlay; i < plays.Count; i++)
        {
            var play = plays[i];
            if (play.CardPlay.Player != _observedCreature.Player
                || play.CardPlay.Card.Type != CardType.Attack
                || !play.HappenedThisTurn(_combatState))
                continue;

            // Use the same history and turn filter as JugglingPower.AfterApplied.
            var count = plays.Take(i + 1).Count(entry =>
                entry.CardPlay.Player == _observedCreature.Player
                && entry.CardPlay.Card.Type == CardType.Attack
                && entry.HappenedThisTurn(_combatState));
            if (count <= 3)
                React(count == 3 ? "happy" : "thinking",
                    $"本回合已打出 {count} 张攻击牌。", urgent: true);
        }
    }

    private void OnJugglingCountRequested()
    {
        if (Visual is null || _combatState is null || _observedCreature?.HasPower<JugglingPower>() != true)
            return;

        var count = CombatManager.Instance.History.CardPlaysStarted.Count(entry =>
            entry.CardPlay.Player == _observedCreature.Player
            && entry.CardPlay.Card.Type == CardType.Attack
            && entry.HappenedThisTurn(_combatState));
        Visual.Call("react", count >= 3 ? "happy" : "thinking",
            $"本回合已打出 {count} 张攻击牌。");
    }

    private void OnRemovalPriceRequested()
    {
        if (Visual is null || !_removalAvailable)
            return;

        try
        {
            var runState = RunManager.Instance.DebugOnlyGetState();
            var player = LocalContext.GetMe(runState);
            if (runState is null || player is null)
                return;

            var inflation = RunManager.Instance.HasAscension(AscensionLevel.Inflation);
            var basePrice = AscensionHelper.GetValueIfAscension(AscensionLevel.Inflation, 100, 75)
                + MerchantCardRemovalEntry.PriceIncrease * player.ExtraFields.CardShopRemovalsUsed;
            var entry = new MerchantCardRemovalEntry(player);
            // Cost only applies merchant hooks inside a merchant room. Apply the same
            // hook explicitly so the estimate also includes current relics elsewhere.
            var price = (int)Hook.ModifyMerchantPrice(runState, player, entry, basePrice);

            var effects = new List<string>();
            if (inflation)
                effects.Add("通货膨胀");

            var membership = player.Relics.Any(relic => relic is MembershipCard && !relic.IsMelted);
            var courier = player.Relics.Any(relic => relic is TheCourier && !relic.IsMelted);
            if (membership)
                effects.Add("会员卡");
            if (courier)
                effects.Add("送货员");

            var vanillaPrice = (int)(basePrice * (membership ? 0.5m : 1m) * (courier ? 0.8m : 1m));
            if (price != vanillaPrice)
                effects.Add("其他价格效果");

            var note = effects.Count == 0 ? "" : $"（{string.Join("、", effects)}）";
            Visual.Call("react", "thinking", $"预计 {price} 金{note}。");
        }
        catch (InvalidOperationException)
        {
            Visual.Call("react", "thinking", "现在还算不出删牌价格。");
        }
    }

    private void SetJugglingAvailable(bool available)
    {
        if (_jugglingAvailable == available)
            return;
        _jugglingAvailable = available;
        Visual?.Call("set_juggling_available", available);
    }

    private void OnTurnStarted(CombatState _)
    {
        if (CombatManager.Instance.IsEnemyTurnStarted)
            return;

        _playerTurns++;
        if (_playerTurns > 1 && _playerTurns % 3 == 0)
            React("idle", "慢慢来，我在看着。", urgent: false);
    }

    private void OnHealthChanged(int previous, int current)
    {
        if (_observedCreature is null || current >= previous)
            return;

        var lowHealth = current <= _observedCreature.MaxHp * 0.3;
        React(lowHealth ? "worried" : "surprised",
            lowHealth ? "先稳住，别勉强。" : "小心！还好吗？", urgent: true);
    }

    private void OnPeekRequested()
    {
        if (Visual is null)
            return;

        if (NGame.Instance?.CurrentRunNode?.CombatRoom is null || _combatState is null)
        {
            Visual.Call("react", "thinking", "现在还没有可看的抽牌堆。");
            return;
        }

        try
        {
            var player = LocalContext.GetMe(_combatState);
            var cards = player?.PlayerCombatState?.DrawPile.Cards;
            if (cards is null || cards.Count == 0)
            {
                Visual.Call("react", "thinking", "抽牌堆暂时是空的。");
                return;
            }

            // MoveToTopInternal inserts at index zero. Read the current order
            // only when requested, since draws and shuffles may change it.
            Visual.Call("react", "thinking", $"下一张是「{cards[0].Title}」。");
        }
        catch (InvalidOperationException)
        {
            Visual.Call("react", "thinking", "现在还看不到你的抽牌堆。");
        }
    }

    private void OnPotionOddsRequested()
    {
        if (Visual is null || _combatState is null || NGame.Instance?.CurrentRunNode?.CombatRoom is null)
            return;

        try
        {
            var player = LocalContext.GetMe(_combatState);
            var room = _combatState.RunState.CurrentRoom;
            if (player is null || room is null)
            {
                Visual.Call("react", "thinking", "现在还算不出掉药率。");
                return;
            }

            var roomType = room.RoomType;
            var baseOdds = player.PlayerOdds.PotionReward.CurrentValue;
            // Match PotionRewardOdds.Roll without consuming RNG or changing its pity value.
            var chance = Math.Clamp(baseOdds + (roomType == RoomType.Elite ? 0.125f : 0f), 0f, 1f);
            var percent = (int)Math.Round(chance * 100f);
            var eliteNote = roomType == RoomType.Elite ? "，已算入精英加成" : "";
            Visual.Call("react", "thinking", $"这场战斗按常规奖励规则，掉药率约 {percent}%{eliteNote}。");
        }
        catch (InvalidOperationException)
        {
            Visual.Call("react", "thinking", "现在还算不出掉药率。");
        }
    }

    private bool CanSl()
    {
        var game = NGame.Instance;
        var manager = RunManager.Instance;
        return !_slInProgress
            && game?.CurrentRunNode is not null
            && game.MainMenu is null
            && manager is not null
            && manager.IsSingleplayerOrFakeMultiplayer
            && !manager.IsCleaningUp
            && !manager.IsGameOver
            && !game.Transition.InTransition
            && SaveManager.Instance.HasRunSave;
    }

    private void OnSlRequested()
    {
        if (!CanSl())
            return;

        _slInProgress = true;
        _slAvailable = false;
        Visual?.Call("set_sl_available", false);
        _ = PerformSlAsync();
    }

    private async Task PerformSlAsync()
    {
        var game = NGame.Instance;
        try
        {
            if (game is null)
                throw new InvalidOperationException("Game scene is missing.");

            // Fade once, then use the same save restoration APIs as Continue.
            // Keeping the main menu out of the path avoids its two-second fade-in
            // and prevents a second Continue click from starting a concurrent load.
            NRunMusicController.Instance?.StopMusic();
            await game.Transition.FadeOut(0.35f);

            var saveManager = SaveManager.Instance;
            var pendingSave = saveManager.CurrentRunSaveTask;
            if (pendingSave is not null)
                await pendingSave;

            var readResult = saveManager.LoadRunSave();
            if (!readResult.Success || readResult.SaveData is null)
                throw new InvalidOperationException("SL stopped: current run save could not be read.");

            var save = readResult.SaveData;
            DetachCreature();
            _combatState = null;
            RunManager.Instance.CleanUp(true);
            // Remove the previous NRun before the asynchronous save setup starts;
            // its _Process would otherwise keep updating the disconnected session.
            game.RootSceneContainer.SetCurrentScene(new Control { Name = "CompanionSlLoading" });
            var runState = RunState.FromSerializable(save);
            await RunManager.Instance.SetUpSavedSingleplayer(runState, save);
            game.ReactionContainer.InitializeNetworking(new NetSingleplayerGameService());
            await game.LoadRun(runState, save.PreFinishedRoom);
            await game.Transition.FadeIn(0.55f);
        }
        catch (Exception error)
        {
            GD.PushError($"[ReactiveCompanionUI] SL failed: {error}");
            if (game is not null)
            {
                try
                {
                    // Leave a usable menu and preserve the run save if direct
                    // restoration fails at any point after the screen fades out.
                    await game.ReturnToMainMenu();
                }
                catch (Exception fallbackError)
                {
                    GD.PushError($"[ReactiveCompanionUI] SL menu fallback failed: {fallbackError}");
                }
            }
            Visual?.Call("react", "worried", "SL 没能完成，请在主菜单检查存档。");
        }
        finally
        {
            _slInProgress = false;
        }
    }

    private void React(string expression, string line, bool urgent)
    {
        if (Visual is null || (!urgent && _reactionCooldown > 0))
            return;

        _reactionCooldown = urgent ? 3.0 : 9.0;
        Visual.Call("react", expression, line);
    }

    private void DetachCreature()
    {
        if (_observedCreature is null)
            return;
        _observedCreature.CurrentHpChanged -= OnHealthChanged;
        _observedCreature = null;
    }
}
