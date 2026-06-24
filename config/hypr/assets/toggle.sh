#!/bin/bash

APP="$1"

if [ -z "$APP" ]; then
    echo "Erro: Nenhum aplicativo especificado."
    echo "Uso: $0 <app>"
    exit 1
fi

# Localização do arquivo de bloqueio para o bemenu (agora armazena o PID)
BEMENU_LOCK_FILE="/tmp/bemenu.pid"

# -----------------------------------------------------------------------------
# FUNÇÃO 'menu' - Específica para abrir o bemenu
# -----------------------------------------------------------------------------
menu() {
    bemenu-run \
        -p "" \
        -c \
        -W 0.2 \
        -l 5 \
        -i \
        -R 8 \
        --auto-select \
        --fn 'JetBrains Mono Nerd Font 11' \
        --nb  "#00000099" --nf "#ffffff99" \
        --sb  "#000000" --sf "#1A1A1A" \
        --hb  "#00000099" --hf "#D0D0D0" \
        --tb  "#1A1A1A" --tf "#D0D0D0" \
        --ff  "#D0D0D0" --fb "#00000099" \
        --cf  "#0000000" --cb "#00000050" \
        --ab  "#00000099" --af "#ffffff99" &
    
    # Salva o PID do último comando em segundo plano ($!) no arquivo
    echo $! > "$BEMENU_LOCK_FILE"
    
    # Espera o bemenu terminar (seleção ou Esc) e remove o lock file
    wait $!
    rm -f "$BEMENU_LOCK_FILE"
}

# -----------------------------------------------------------------------------
# LÓGICA PRINCIPAL DE TOGGLE (ALTERNAR)
# -----------------------------------------------------------------------------

if [ "$APP" = "bemenu" ]; then
    if [ -f "$BEMENU_LOCK_FILE" ]; then
        PID=$(cat "$BEMENU_LOCK_FILE")
        kill "$PID"
        rm -f "$BEMENU_LOCK_FILE"
    else
        menu
    fi
else
    if pgrep -x "$APP" >/dev/null 2>&1; then
        pkill -x "$APP"
    else
        "$APP"
    fi
fi
