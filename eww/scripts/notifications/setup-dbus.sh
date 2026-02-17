#!/bin/bash

SCRIPT_DIR="$HOME/.config/eww/scripts/notifications"
SERVICE_FILE="$HOME/.local/share/dbus-1/services/org.freedesktop.Notifications.service"

echo "  Configurando Sistema de Notificações EWW v3.0"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

echo "[1/7] Configurando serviço D-Bus..."
mkdir -p "$(dirname "$SERVICE_FILE")"

cat > "$SERVICE_FILE" << 'EOF'
[D-BUS Service]
Name=org.freedesktop.Notifications
Exec=/usr/lib/notification-daemon-1.0/notification-daemon
EOF

echo "✓ Serviço D-Bus configurado"
echo ""

echo "[2/7] Configurando permissões dos scripts..."
chmod +x "$SCRIPT_DIR/daemon.sh" 2>/dev/null
chmod +x "$SCRIPT_DIR/watcher.sh" 2>/dev/null
chmod +x "$SCRIPT_DIR/display.sh" 2>/dev/null
chmod +x "$SCRIPT_DIR/manager.sh" 2>/dev/null
chmod +x "$SCRIPT_DIR/notify-send" 2>/dev/null

echo "✓ Permissões configuradas"
echo ""

echo "[3/7] Migrando notificações existentes..."
if [ -f "$SCRIPT_DIR/migrate-notifications.sh" ]; then
    chmod +x "$SCRIPT_DIR/migrate-notifications.sh"
    "$SCRIPT_DIR/migrate-notifications.sh"
else
    echo "⚠ Script de migração não encontrado"
fi
echo ""

echo "[4/7] Recarregando EWW..."
eww reload
sleep 1
echo "✓ EWW recarregado"
echo ""

echo "[5/7] Abrindo janelas de notificações..."
eww open notification-toast-1 2>/dev/null
eww open notification-toast-2 2>/dev/null
eww open notification-toast-3 2>/dev/null
echo "✓ Janelas abertas"
echo ""

echo "[6/7] Parando processos antigos..."
pkill -f "notifications/daemon.sh"
pkill -f "notifications/watcher.sh"
sleep 1
echo "✓ Processos antigos parados"
echo ""

echo "[7/7] Iniciando serviços..."

if [ -f "$SCRIPT_DIR/daemon.sh" ]; then
    "$SCRIPT_DIR/daemon.sh" &
    DAEMON_PID=$!
    echo "  ✓ Daemon D-Bus iniciado (PID: $DAEMON_PID)"
else
    echo "  ✗ daemon.sh não encontrado!"
fi

if [ -f "$SCRIPT_DIR/watcher.sh" ]; then
    "$SCRIPT_DIR/watcher.sh" &
    WATCHER_PID=$!
    echo "  ✓ Watcher iniciado (PID: $WATCHER_PID)"
else
    echo "  ✗ watcher.sh não encontrado!"
fi

echo ""

sleep 2

DAEMON_RUNNING=false
WATCHER_RUNNING=false

if ps -p $DAEMON_PID > /dev/null 2>&1; then
    DAEMON_RUNNING=true
fi

if ps -p $WATCHER_PID > /dev/null 2>&1; then
    WATCHER_RUNNING=true
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

if $DAEMON_RUNNING && $WATCHER_RUNNING; then
    echo "Sistema configurado com sucesso!"
else
    echo "Sistema configurado com avisos"
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  STATUS DOS SERVIÇOS:"
echo ""

if $DAEMON_RUNNING; then
    echo "  ✓ Daemon D-Bus: RODANDO (PID: $DAEMON_PID)"
else
    echo "  ✗ Daemon D-Bus: NÃO RODANDO"
fi

if $WATCHER_RUNNING; then
    echo "  ✓ Watcher: RODANDO (PID: $WATCHER_PID)"
else
    echo "  ✗ Watcher: NÃO RODANDO"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  COMO FUNCIONA (v3.0):"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "1. TODAS notificações são salvas com dispatch: false"
echo "   • notify-send → JSON (dispatch: false)"
echo "   • Apps externos → D-Bus → JSON (dispatch: false)"
echo ""
echo "2. Watcher monitora continuamente (a cada 1s)"
echo "   • Detecta notificações com dispatch: false"
echo "   • Adiciona à fila de exibição"
echo "   • Dispara popup na tela"
echo "   • Marca dispatch: true"
echo ""
echo "3. Nenhuma notificação é perdida"
echo "   • Se watcher falhar, tenta novamente"
echo "   • Notificações ficam na fila até serem exibidas"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  TESTAR:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  notify-send 'Teste' 'Notificação de teste'"
echo "  notify-send -u critical 'Urgente' 'Alta prioridade'"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "  MONITORAR:"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "  # Ver processos"
echo "  ps aux | grep -E 'daemon.sh|watcher.sh'"
echo ""
echo "  # Ver notificações não disparadas"
echo "  jq '[.notifications[] | select(.dispatch == false)]' \\"
echo "     ~/.local/share/eww/notifications.json"
echo ""
echo "  # Ver fila"
echo "  cat ~/.cache/eww/notifications/queue"
echo ""

if ! $DAEMON_RUNNING || ! $WATCHER_RUNNING; then
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo "  AÇÃO NECESSÁRIA:"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    
    if ! $DAEMON_RUNNING; then
        echo "Iniciar daemon manualmente:"
        echo "  $SCRIPT_DIR/daemon.sh &"
        echo ""
    fi
    
    if ! $WATCHER_RUNNING; then
        echo "Iniciar watcher manualmente:"
        echo "  $SCRIPT_DIR/watcher.sh &"
        echo ""
    fi
fi

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
