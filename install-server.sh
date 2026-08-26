#!/usr/bin/env bash
# server dotfiles installer
# installs configs + optional tools to ~/.local (no sudo required)
#
# usage:
#   curl -fsSL https://raw.githubusercontent.com/FlynnOConnell/.dotfiles/master/install-server.sh | bash
#   ./install-server.sh

set -e

# colors
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
GRAY='\033[0;90m'
NC='\033[0m'

info() { echo -e "${BLUE}[INFO]${NC} $*"; }
ok() { echo -e "${GREEN}[OK]${NC} $*"; }
warn() { echo -e "${YELLOW}[WARN]${NC} $*"; }
err() { echo -e "${RED}[ERROR]${NC} $*"; }

# detect architecture
ARCH=$(uname -m)
case "$ARCH" in
    x86_64) ARCH_SUFFIX="x86_64" ;;
    aarch64|arm64) ARCH_SUFFIX="aarch64" ;;
    *) err "unsupported architecture: $ARCH"; exit 1 ;;
esac

OS=$(uname -s | tr '[:upper:]' '[:lower:]')

# directories
DOTFILES_ROOT="${DOTFILES_ROOT:-$HOME/.dotfiles}"
LOCAL_BIN="$HOME/.local/bin"
LOCAL_SHARE="$HOME/.local/share"

banner() {
    echo ""
    echo -e "${BLUE}  ___        _    __ _ _           ${NC}"
    echo -e "${BLUE} |   \\  ___ | |_ / _(_) | ___  ___ ${NC}"
    echo -e "${BLUE} | |) |/ _ \\|  _|  _| | |/ -_)(_-< ${NC}"
    echo -e "${BLUE} |___/ \\___/ \\__|_| |_|_|\\___|/__/ ${NC}"
    echo ""
    echo "Server Dotfiles Installer (no sudo required)"
    echo ""
}

command_exists() {
    command -v "$1" &>/dev/null
}

# latest release version for a repo, without any leading "v".
# the api returns pretty-printed json for some repos and one long line for
# others, so isolate the field with grep -o instead of trusting line structure -
# a greedy sed over a single-line blob captures garbage.
gh_latest_version() {
    local json
    json=$(curl -fsSL "https://api.github.com/repos/$1/releases/latest") || return 1
    printf '%s' "$json" | grep -o '"tag_name"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | cut -d'"' -f4 | sed 's/^v//'
}

ensure_dirs() {
    mkdir -p "$LOCAL_BIN"
    mkdir -p "$LOCAL_SHARE"
    mkdir -p "$HOME/.config"
}

clone_dotfiles() {
    if [[ -d "$DOTFILES_ROOT" && -f "$DOTFILES_ROOT/install-server.conf.yaml" ]]; then
        info "dotfiles already cloned at $DOTFILES_ROOT"
        return
    fi

    info "cloning dotfiles to $DOTFILES_ROOT..."
    git clone --recursive https://github.com/FlynnOConnell/.dotfiles.git "$DOTFILES_ROOT"
    ok "dotfiles cloned"
}

setup_path() {
    # add ~/.local/bin to PATH if not already
    if [[ ":$PATH:" != *":$LOCAL_BIN:"* ]]; then
        export PATH="$LOCAL_BIN:$PATH"
    fi

    # add to shell rc if not present
    local shell_rc=""
    if [[ -n "$ZSH_VERSION" ]] || [[ "$SHELL" == *"zsh"* ]]; then
        shell_rc="$HOME/.zshrc"
    else
        shell_rc="$HOME/.bashrc"
    fi

    if [[ -f "$shell_rc" ]] && ! grep -q 'export PATH="$HOME/.local/bin:$PATH"' "$shell_rc" 2>/dev/null; then
        echo 'export PATH="$HOME/.local/bin:$PATH"' >> "$shell_rc"
        info "added ~/.local/bin to PATH in $shell_rc"
    fi
}

# install uv (python package manager)
install_uv() {
    if command_exists uv; then
        ok "uv already installed: $(uv --version)"
        return
    fi

    info "installing uv..."
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
    ok "uv installed"
}

# install dotbot via uv
install_dotbot() {
    if uv tool list 2>/dev/null | grep -q "dotbot"; then
        ok "dotbot already installed"
        return
    fi

    info "installing dotbot via uv..."
    uv tool install dotbot
    ok "dotbot installed"
}

# symlink configs via dotbot
install_configs() {
    info "symlinking configurations..."

    cd "$DOTFILES_ROOT"
    git submodule update --init --recursive 2>/dev/null || true

    if command_exists dotbot; then
        dotbot -d "$DOTFILES_ROOT" -c "$DOTFILES_ROOT/install-server.conf.yaml"
        ok "configurations linked"
    else
        # fallback: use uv run
        uv tool run dotbot -d "$DOTFILES_ROOT" -c "$DOTFILES_ROOT/install-server.conf.yaml"
        ok "configurations linked"
    fi
}

# install neovim (appimage or prebuilt)
install_neovim() {
    if command_exists nvim; then
        ok "neovim already installed: $(nvim --version | head -1)"
        return 0
    fi

    info "installing neovim..."

    local nvim_url=""
    local nvim_file=""

    if [[ "$OS" == "linux" ]]; then
        # try appimage first (most compatible)
        nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH_SUFFIX}.appimage"
        nvim_file="$LOCAL_BIN/nvim"

        if curl -fsSL "$nvim_url" -o "$nvim_file" 2>/dev/null; then
            chmod +x "$nvim_file"

            # test if appimage works (some servers lack FUSE)
            if ! "$nvim_file" --version &>/dev/null; then
                warn "appimage failed (no FUSE?), extracting..."
                cd "$LOCAL_SHARE"
                "$nvim_file" --appimage-extract &>/dev/null || true
                rm "$nvim_file"
                ln -sf "$LOCAL_SHARE/squashfs-root/usr/bin/nvim" "$nvim_file"
            fi
            ok "neovim installed"
            return 0
        fi

        # fallback: tarball
        nvim_url="https://github.com/neovim/neovim/releases/latest/download/nvim-linux-${ARCH_SUFFIX}.tar.gz"
        if curl -fsSL "$nvim_url" | tar xz -C "$LOCAL_SHARE" 2>/dev/null; then
            ln -sf "$LOCAL_SHARE/nvim-linux-${ARCH_SUFFIX}/bin/nvim" "$nvim_file"
            ok "neovim installed (tarball)"
            return 0
        fi
    fi

    warn "could not install neovim automatically"
    return 1
}

# install fzf
install_fzf() {
    if command_exists fzf; then
        ok "fzf already installed"
        return 0
    fi

    info "installing fzf..."

    # asset names are fzf-<version>-linux_<goarch>.tar.gz, not the arch triple
    local fzf_arch="amd64"
    [[ "$ARCH_SUFFIX" == "aarch64" ]] && fzf_arch="arm64"
    local fzf_version
    fzf_version=$(gh_latest_version junegunn/fzf)
    local fzf_url="https://github.com/junegunn/fzf/releases/download/v${fzf_version}/fzf-${fzf_version}-${OS}_${fzf_arch}.tar.gz"

    if [[ -n "$fzf_version" ]] && curl -fsSL "$fzf_url" | tar xz -C "$LOCAL_BIN" 2>/dev/null; then
        ok "fzf installed"
        return 0
    fi

    # fallback: git install
    if [[ ! -d "$HOME/.fzf" ]]; then
        git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
        "$HOME/.fzf/install" --bin --no-update-rc
        ln -sf "$HOME/.fzf/bin/fzf" "$LOCAL_BIN/fzf"
        ok "fzf installed (git)"
        return 0
    fi

    warn "could not install fzf"
    return 1
}

# install ripgrep
install_ripgrep() {
    if command_exists rg; then
        ok "ripgrep already installed"
        return 0
    fi

    info "installing ripgrep..."

    # get latest version
    local rg_version
    rg_version=$(gh_latest_version BurntSushi/ripgrep)
    [[ -n "$rg_version" ]] || { warn "could not determine rg version"; return 1; }

    local rg_url="https://github.com/BurntSushi/ripgrep/releases/download/${rg_version}/ripgrep-${rg_version}-${ARCH_SUFFIX}-unknown-linux-musl.tar.gz"

    if curl -fsSL "$rg_url" | tar xz -C "/tmp" 2>/dev/null; then
        cp "/tmp/ripgrep-${rg_version}-${ARCH_SUFFIX}-unknown-linux-musl/rg" "$LOCAL_BIN/"
        chmod +x "$LOCAL_BIN/rg"
        rm -rf "/tmp/ripgrep-${rg_version}-${ARCH_SUFFIX}-unknown-linux-musl"
        ok "ripgrep installed"
        return 0
    fi

    warn "could not install ripgrep"
    return 1
}

# install fd
install_fd() {
    if command_exists fd; then
        ok "fd already installed"
        return 0
    fi

    info "installing fd..."

    local fd_version
    fd_version=$(gh_latest_version sharkdp/fd)
    [[ -n "$fd_version" ]] || { warn "could not determine fd version"; return 1; }

    local fd_url="https://github.com/sharkdp/fd/releases/download/v${fd_version}/fd-v${fd_version}-${ARCH_SUFFIX}-unknown-linux-musl.tar.gz"

    if curl -fsSL "$fd_url" | tar xz -C "/tmp" 2>/dev/null; then
        cp "/tmp/fd-v${fd_version}-${ARCH_SUFFIX}-unknown-linux-musl/fd" "$LOCAL_BIN/"
        chmod +x "$LOCAL_BIN/fd"
        rm -rf "/tmp/fd-v${fd_version}-${ARCH_SUFFIX}-unknown-linux-musl"
        ok "fd installed"
        return 0
    fi

    warn "could not install fd"
    return 1
}

# install lazygit
install_lazygit() {
    if command_exists lazygit; then
        ok "lazygit already installed"
        return 0
    fi

    info "installing lazygit..."

    local lg_version
    lg_version=$(gh_latest_version jesseduffield/lazygit)
    [[ -n "$lg_version" ]] || { warn "could not determine lg version"; return 1; }

    local arch_name="$ARCH_SUFFIX"
    [[ "$arch_name" == "aarch64" ]] && arch_name="arm64"

    local lg_url="https://github.com/jesseduffield/lazygit/releases/download/v${lg_version}/lazygit_${lg_version}_Linux_${arch_name}.tar.gz"

    if curl -fsSL "$lg_url" | tar xz -C "$LOCAL_BIN" lazygit 2>/dev/null; then
        chmod +x "$LOCAL_BIN/lazygit"
        ok "lazygit installed"
        return 0
    fi

    warn "could not install lazygit"
    return 1
}

# install starship prompt
install_starship() {
    if command_exists starship; then
        ok "starship already installed"
        return 0
    fi

    info "installing starship..."

    if curl -fsSL https://starship.rs/install.sh | sh -s -- --yes --bin-dir "$LOCAL_BIN" 2>/dev/null; then
        ok "starship installed"
        return 0
    fi

    warn "could not install starship"
    return 1
}

# install zoxide
install_zoxide() {
    if command_exists zoxide; then
        ok "zoxide already installed"
        return 0
    fi

    info "installing zoxide..."

    if curl -sSfL https://raw.githubusercontent.com/ajeetdsouza/zoxide/main/install.sh | sh 2>/dev/null; then
        ok "zoxide installed"
        return 0
    fi

    warn "could not install zoxide"
    return 1
}

# install bat
install_bat() {
    if command_exists bat || command_exists batcat; then
        ok "bat already installed"
        return 0
    fi

    info "installing bat..."

    local bat_version
    bat_version=$(gh_latest_version sharkdp/bat)
    [[ -n "$bat_version" ]] || { warn "could not determine bat version"; return 1; }

    local bat_url="https://github.com/sharkdp/bat/releases/download/v${bat_version}/bat-v${bat_version}-${ARCH_SUFFIX}-unknown-linux-musl.tar.gz"

    if curl -fsSL "$bat_url" | tar xz -C "/tmp" 2>/dev/null; then
        cp "/tmp/bat-v${bat_version}-${ARCH_SUFFIX}-unknown-linux-musl/bat" "$LOCAL_BIN/"
        chmod +x "$LOCAL_BIN/bat"
        rm -rf "/tmp/bat-v${bat_version}-${ARCH_SUFFIX}-unknown-linux-musl"
        ok "bat installed"
        return 0
    fi

    warn "could not install bat"
    return 1
}

# install delta (git diff)
install_delta() {
    if command_exists delta; then
        ok "delta already installed"
        return 0
    fi

    info "installing delta..."

    local delta_version
    delta_version=$(gh_latest_version dandavison/delta)
    [[ -n "$delta_version" ]] || { warn "could not determine delta version"; return 1; }

    local delta_url="https://github.com/dandavison/delta/releases/download/${delta_version}/delta-${delta_version}-${ARCH_SUFFIX}-unknown-linux-musl.tar.gz"

    if curl -fsSL "$delta_url" | tar xz -C "/tmp" 2>/dev/null; then
        cp "/tmp/delta-${delta_version}-${ARCH_SUFFIX}-unknown-linux-musl/delta" "$LOCAL_BIN/"
        chmod +x "$LOCAL_BIN/delta"
        rm -rf "/tmp/delta-${delta_version}-${ARCH_SUFFIX}-unknown-linux-musl"
        ok "delta installed"
        return 0
    fi

    warn "could not install delta"
    return 1
}

# install eza (ls replacement)
install_eza() {
    if command_exists eza; then
        ok "eza already installed"
        return 0
    fi

    info "installing eza..."

    local eza_version
    eza_version=$(gh_latest_version eza-community/eza)
    [[ -n "$eza_version" ]] || { warn "could not determine eza version"; return 1; }

    local arch_name="$ARCH_SUFFIX"
    local eza_url="https://github.com/eza-community/eza/releases/download/v${eza_version}/eza_${arch_name}-unknown-linux-musl.tar.gz"

    if curl -fsSL "$eza_url" | tar xz -C "$LOCAL_BIN" 2>/dev/null; then
        chmod +x "$LOCAL_BIN/eza"
        ok "eza installed"
        return 0
    fi

    warn "could not install eza"
    return 1
}

# setup python provider for neovim
setup_neovim_python() {
    if ! command_exists uv; then
        warn "uv not installed, skipping neovim python setup"
        return
    fi

    info "setting up neovim python provider..."

    local nvim_venv="$HOME/.local/share/nvim-python"

    if [[ ! -d "$nvim_venv" ]]; then
        uv venv "$nvim_venv" --python 3.12 2>/dev/null || uv venv "$nvim_venv" 2>/dev/null
    fi

    uv pip install pynvim --python "$nvim_venv/bin/python" 2>/dev/null
    ok "neovim python provider ready at $nvim_venv"
}

# install python tools via uv
install_uv_tools() {
    if ! command_exists uv; then
        return
    fi

    info "installing python tools via uv..."

    local tools=("ruff" "ty")
    for tool in "${tools[@]}"; do
        if uv tool list 2>/dev/null | grep -q "$tool"; then
            ok "$tool already installed"
        else
            uv tool install "$tool" 2>/dev/null && ok "$tool installed" || warn "failed to install $tool"
        fi
    done
}

show_menu() {
    # menu goes to stderr and the answer is read from the terminal, so the
    # caller can capture just the selection on stdout.
    {
        echo ""
        echo "Optional Tools (installed to ~/.local/bin)"
        echo ""
        echo "  [1] neovim     - hyperextensible vim-based text editor"
        echo "  [2] fzf        - command-line fuzzy finder"
        echo "  [3] ripgrep    - fast regex search tool (rg)"
        echo "  [4] fd         - fast find alternative"
        echo "  [5] lazygit    - terminal UI for git"
        echo "  [6] starship   - cross-shell prompt"
        echo "  [7] zoxide     - smarter cd command"
        echo "  [8] bat        - cat with syntax highlighting"
        echo "  [9] delta      - git diff viewer"
        echo "  [10] eza       - modern ls replacement"
        echo ""
        echo "  [A] All - install all tools"
        echo "  [E] Essentials - neovim, fzf, ripgrep, fd, lazygit"
        echo "  [N] None - skip tool installation"
        echo ""
        printf "Select tools (comma-separated numbers, A/E/N): "
    } >&2

    local selection=""
    { read -r selection </dev/tty; } 2>/dev/null || true
    echo "${selection:-N}" | tr '[:lower:]' '[:upper:]'
}

# non-interactive selection: DOTFILES_TOOLS=all|essentials|none|1,3,5
# used by hpc/deploy.sh and by `curl ... | bash`, where stdin is the script.
resolve_tools() {
    if [[ -n "${DOTFILES_TOOLS:-}" ]]; then
        echo "$DOTFILES_TOOLS" | tr '[:lower:]' '[:upper:]'
    elif [[ -t 0 ]] || (: </dev/tty) 2>/dev/null; then
        # -r /dev/tty is not enough: it passes in contexts where opening the
        # terminal still fails, which would print the menu and then die.
        show_menu
    else
        warn "no terminal for the tool menu; set DOTFILES_TOOLS to install tools" >&2
        echo "N"
    fi
}

# tools are independent, and release URLs break or rate-limit from time to time.
# a single failure must not abort the run, so each install is isolated and the
# failures are collected and reported at the end.
FAILED_TOOLS=()
try_install() {
    local name="$1"
    if "install_${name}"; then
        return 0
    else
        FAILED_TOOLS+=("$name")
        return 0
    fi
}

install_selected_tools() {
    local selection="$1"
    local all=(neovim fzf ripgrep fd lazygit starship zoxide bat delta eza)
    local essentials=(neovim fzf ripgrep fd lazygit)
    local t

    case "$selection" in
        N|NONE)
            info "skipping tool installation"
            return 0
            ;;
        A|ALL)
            for t in "${all[@]}"; do try_install "$t"; done
            return 0
            ;;
        E|ESSENTIALS)
            for t in "${essentials[@]}"; do try_install "$t"; done
            return 0
            ;;
    esac

    # comma-separated numbers, indexing into $all
    local choice
    IFS=',' read -ra choices <<< "$selection"
    for choice in "${choices[@]}"; do
        choice="${choice// /}"
        if [[ "$choice" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#all[@]} )); then
            try_install "${all[$((choice - 1))]}"
        else
            warn "ignoring unknown selection: $choice"
        fi
    done
    return 0
}

show_summary() {
    echo ""
    echo -e "${GREEN}Installation Complete${NC}"
    echo ""
    echo "  Configs linked:"
    echo "    ~/.config/nvim      - neovim configuration"
    echo "    ~/.bashrc           - server-optimized shell config"
    echo "    ~/.aliases          - portable aliases (no GUI/Windows deps)"
    echo "    ~/.config/lazygit   - lazygit configuration"
    echo "    ~/.config/btop      - btop themes"
    echo "    ~/.config/tmux      - tmux configuration"
    echo "    ~/.config/starship  - prompt configuration"
    echo "    ~/.vimrc            - vim configuration"
    echo ""
    echo "  Tools installed to: ~/.local/bin"
    echo ""
    echo "  Machine-specific customizations:"
    echo "    create ~/.bashrc.local for local overrides (not tracked)"
    echo ""
    if [[ -d /biohpc || -d /lustre || -n "$(command -v sbatch || command -v qsub)" ]]; then
        echo "  Cluster detected - the shell config loads hpc/hpc.sh automatically."
        echo "    hpc-where    show site, locations, free space"
        echo "    hpc-help     transfer + scheduler helpers"
        echo "    if ~/.bashrc is not ours, run: bash ~/.dotfiles/hpc/setup.sh"
        echo ""
    fi

    if (( ${#FAILED_TOOLS[@]} > 0 )); then
        warn "these tools did not install: ${FAILED_TOOLS[*]}"
        echo "    re-run to retry - release downloads fail transiently"
        echo ""
    fi

    echo -e "  ${YELLOW}NEXT STEPS:${NC}"
    echo "    1. restart your shell or run: source ~/.bashrc"
    echo "    2. open nvim and run :Lazy sync to install plugins"
    echo "    3. run :checkhealth to verify setup"
    echo ""
}

main() {
    banner

    ensure_dirs
    setup_path

    # if not in dotfiles dir, clone it
    if [[ ! -f "$DOTFILES_ROOT/install-server.conf.yaml" ]]; then
        clone_dotfiles
    fi

    cd "$DOTFILES_ROOT"

    # install uv and dotbot
    install_uv
    install_dotbot

    # symlink configs
    install_configs

    # tool selection
    selection=$(resolve_tools)
    install_selected_tools "$selection"

    # python setup
    setup_neovim_python
    install_uv_tools

    show_summary
}

main "$@"
