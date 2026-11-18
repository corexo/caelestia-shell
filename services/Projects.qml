pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import Caelestia.Config
import qs.utils

// Projects are named Hyprland workspaces (name:<project>), separate from the numbered ones.
// Stored in ~/.config/caelestia/projects.json: [{ name, dir, short, colour, port }]
// port: Chromium debug port of the project's browser (scripts/project-browser), for agents
Singleton {
    id: root

    property list<var> list: []
    // Dialog in modules/projects: open with no project = new, with a project = edit
    property bool dialogOpen
    property var editing: null
    // Project under the mouse in the bar, shown by the "project" popout
    property string hovered
    readonly property list<string> colours: ["#ffbad6", "#ffbfa3", "#8fd6a8", "#9ccaff", "#f5c06b"]

    function find(name: string): var {
        return list.find(p => p.name === name) ?? null;
    }

    function add(name: string, dir: string, short: string, colour: string): string {
        // Names go into a Lua string in the Hyprland dispatch, so keep them plain
        if (!/^[A-Za-z0-9._-]{1,40}$/.test(name))
            return "Name darf nur Buchstaben, Ziffern, . _ - enthalten";
        if (find(name))
            return `Projekt ${name} gibt es schon`;

        const initials = name.split(/[-_.]/).filter(Boolean);
        list = [...list, {
                name,
                dir: dir || `${Paths.home}/projects/${name}`,
                short: (short || (initials.length > 1 ? initials[0][0] + initials[1][0] : name.slice(0, 2))).toUpperCase().slice(0, 3),
                colour: colour || colours[list.length % colours.length],
                port: nextPort()
            }];
        save();
        return "";
    }

    // "wait": an agent question for a window of this project is still open (Notifs, scripts/agent-notify)
    // "busy": a terminal title starts with Claude Code's braille spinner
    // shortcut: busy only knows Claude Code; Codex sets no working marker in its title
    function status(name: string): string {
        if (Notifs.notClosed.some(n => n.stays && Notifs.sourceToplevel(n)?.workspace?.name === name))
            return "wait";
        const ws = Hypr.workspaces.values.find(w => w.name === name);
        if (ws?.toplevels.values.some(t => /^[⠀-⣿]/.test(t.title)))
            return "busy";
        return "";
    }

    function openDialog(project: var): void {
        editing = project ?? null;
        dialogOpen = true;
    }

    // Name stays fixed: it is the Hyprland workspace name
    function update(name: string, dir: string, short: string, colour: string): void {
        list = list.map(p => p.name === name ? Object.assign({}, p, {
                dir: dir || p.dir,
                short: (short || p.short).toUpperCase().slice(0, 3),
                colour: colour || p.colour
            }) : p);
        save();
    }

    function remove(name: string): void {
        list = list.filter(p => p.name !== name);
        save();
    }

    function open(name: string): void {
        if (find(name))
            Hypr.focusWorkspace(`name:${name}`);
    }

    // Switch to the project, then start the program in its folder so the window lands there
    function launch(name: string, kind: string): void {
        const p = find(name);
        if (!p)
            return;
        const term = GlobalConfig.general.apps.terminal; // e.g. ["ghostty", "-e"]
        // kind: "terminal", "browser" or an agent CLI ("claude", "codex", "agy")
        const command = ["claude", "codex", "agy"].includes(kind) ? [...term, kind] : kind === "browser" ? [Quickshell.shellPath("scripts/project-browser"), "open", name] : [term[0]];
        open(name);
        Quickshell.execDetached({
            command,
            workingDirectory: p.dir
        });
    }

    function nextPort(): int {
        return Math.max(9300, ...list.map(p => p.port ?? 0)) + 1;
    }

    function save(): void {
        storage.setText(JSON.stringify(list, null, 2) + "\n");
    }

    FileView {
        id: storage

        path: `${Paths.config}/projects.json`
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            try {
                const data = JSON.parse(text());
                root.list = Array.isArray(data) ? data.filter(p => p?.name) : [];
                // Older entries have no browser port yet: give them one
                if (root.list.some(p => !p.port)) {
                    root.list = root.list.reduce((acc, p) => [...acc, p.port ? p : Object.assign({}, p, {
                                port: Math.max(9300, ...root.list.map(q => q.port ?? 0), ...acc.map(q => q.port)) + 1
                            })], []);
                    root.save();
                }
            } catch (e) {
                console.warn(`projects.json: ${e}`);
            }
        }
    }
}
