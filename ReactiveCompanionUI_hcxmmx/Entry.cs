using System.Reflection;
using Godot;
using HarmonyLib;
using MegaCrit.Sts2.Core.Modding;
using MegaCrit.Sts2.Core.Nodes;
using MegaCrit.Sts2.Core.Nodes.Screens.MainMenu;

namespace ReactiveCompanionUI;

[ModInitializer(nameof(Initialize))]
public partial class Entry
{
    public const string ModId = "ReactiveCompanionUI";
    private const string HudScenePath = "res://ReactiveCompanionUI_hcxmmx/scenes/companion_hud.tscn";

    public static void Initialize()
    {
        new Harmony(ModId).PatchAll(Assembly.GetExecutingAssembly());
        GD.Print($"[{ModId}] Initialized");
    }

    [HarmonyPatch(typeof(NGame), nameof(NGame._Ready))]
    private static class NGameReadyPatch
    {
        private static void Postfix(NGame __instance)
        {
            AttachIfMissing(__instance);
        }
    }

    // The game loads mods during NGame._Ready, after Harmony has already entered
    // that method. The menu and run hooks cover that first startup as well as reloads.
    [HarmonyPatch(typeof(NMainMenu), nameof(NMainMenu._Ready))]
    private static class MainMenuReadyPatch
    {
        private static void Postfix() => AttachIfMissing(NGame.Instance);
    }

    [HarmonyPatch(typeof(NRun), nameof(NRun._Ready))]
    private static class RunReadyPatch
    {
        private static void Postfix() => AttachIfMissing(NGame.Instance);
    }

    private static void AttachIfMissing(NGame? game)
    {
        if (game is null || game.GetNodeOrNull<Node>(ModId) is not null)
            return;

        var scene = ResourceLoader.Load<PackedScene>(HudScenePath);
        if (scene is null)
        {
            GD.PushError($"[{ModId}] Missing scene: {HudScenePath}");
            return;
        }

        var visual = scene.Instantiate<Control>();
        visual.Name = ModId;
        game.AddChild(visual);

        // NGame survives menu/run scene changes. Keep the companion above the
        // current scene but below native modal, tooltip, and transition nodes.
        game.MoveChild(visual, game.RootSceneContainer.GetIndex() + 1);

        var bridge = new CompanionBridge { Name = "CompanionBridge", Visual = visual };
        visual.AddChild(bridge);
        GD.Print($"[{ModId}] HUD attached to NGame");
    }
}
