// Main executable of "tmux boot.app", the launcher the tmux-server LaunchAgent
// opens at login.
//
// macOS grants Local Network access per app. A tmux server started straight by
// launchd belongs to no app, so it and everything run inside it (kubectl,
// talosctl, Claude Code) get "no route to host" for LAN addresses and never
// get a toggle in System Settings. Started from this bundle instead, the
// server is attributed to "tmux boot", which shows up under Privacy & Security
// -> Local Network and can be switched on once.
//
// It runs boot-tmux.sh, then stays alive for as long as the tmux server does,
// so the server's responsible app never goes away underneath it.

#include <spawn.h>
#include <stdio.h>
#include <stdlib.h>
#include <sys/wait.h>
#include <unistd.h>

extern char **environ;

static int run(char *const argv[]) {
    pid_t pid;
    int status;
    if (posix_spawnp(&pid, argv[0], NULL, NULL, argv, environ) != 0) {
        perror(argv[0]);
        return -1;
    }
    if (waitpid(pid, &status, 0) < 0) return -1;
    return WIFEXITED(status) ? WEXITSTATUS(status) : -1;
}

int main(void) {
    const char *home = getenv("HOME");
    if (!home) return 1;

    char script[1024];
    snprintf(script, sizeof script, "%s/.tmux/scripts/boot-tmux.sh", home);
    char *boot[] = {script, NULL};
    if (run(boot) != 0) return 1;

    char *probe[] = {"tmux", "list-sessions", NULL};
    while (run(probe) == 0) sleep(60);
    return 0;
}
