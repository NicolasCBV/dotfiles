#!/bin/bash

# ============================================================================
# Google Calendar OAuth2 Setup - Oficial e Direto
# ============================================================================

CONFIG_DIR="$HOME/.local/eww/gcal-sync"
if [ -d $CONFIG_DIR ]; then
    mkdir -p $CONFIG_DIR
fi

CRED_DIR="/etc/eww/cred"
if [ -d $CRED_DIR ]; then
    mkdir-p $CRED_DIR
fi

CLIENT_FILE="${CRED_DIR}/client_secret.json"
TOKEN_FILE="${CRED_DIR}/token.json"

echo "Configuração OAuth2 - Google Calendar API"
echo "=============================================="
echo ""

setup_credentials() {
    echo "PASSO 1: Criar credenciais OAuth2"
    echo ""
    echo "1. Acesse: https://console.cloud.google.com/"
    echo "2. Crie um novo projeto (ou use existente)"
    echo "3. Ative a API: https://console.cloud.google.com/apis/library/calendar-json.googleapis.com"
    echo "4. Vá em: APIs & Services > Credentials"
    echo "5. Clique em: Create Credentials > OAuth client ID"
    echo "6. Tipo: Desktop app"
    echo "7. Nome: EWW Calendar Sync"
    echo "8. Baixe o JSON e salve como: $CLIENT_FILE"
    echo ""
    read -p "Pressione ENTER após salvar o arquivo..."
    
    if [ ! -f "$CLIENT_FILE" ]; then
        echo "❌ Arquivo não encontrado: $CLIENT_FILE"
        exit 1
    fi
    
    echo "Credenciais encontradas"
}

generate_auth_url() {
    echo ""
    echo "PASSO 2: Autenticação"
    echo ""
    
    CLIENT_ID=$(jq -r '.installed.client_id' "$CLIENT_FILE")
    CLIENT_SECRET=$(jq -r '.installed.client_secret' "$CLIENT_FILE")
    REDIRECT_URI="urn:ietf:wg:oauth:2.0:oob"
    SCOPE="https://www.googleapis.com/auth/calendar.readonly"
    
    AUTH_URL="https://accounts.google.com/o/oauth2/v2/auth"
    AUTH_URL+="?client_id=$CLIENT_ID"
    AUTH_URL+="&redirect_uri=$REDIRECT_URI"
    AUTH_URL+="&response_type=code"
    AUTH_URL+="&scope=$SCOPE"
    AUTH_URL+="&access_type=offline"
    AUTH_URL+="&prompt=consent"
    
    echo "Abra esta URL no navegador:"
    echo ""
    echo "$AUTH_URL"
    echo ""
    
    if command -v xdg-open &>/dev/null; then
        echo "Abrindo navegador..."
        xdg-open "$AUTH_URL" 2>/dev/null || true
    fi
    
    echo ""
    echo "Após autorizar, você receberá um CÓDIGO."
    echo ""
    read -p "Cole o código aqui: " AUTH_CODE
    
    if [ -z "$AUTH_CODE" ]; then
        echo "Código não fornecido"
        exit 1
    fi
    
    exchange_code "$AUTH_CODE" "$CLIENT_ID" "$CLIENT_SECRET"
}

exchange_code() {
    local code="$1"
    local client_id="$2"
    local client_secret="$3"
    local TMP_FILE="/tmp/token_$$.json"

    echo ""
    echo "Obtendo token de acesso..."

    TOKEN_RESPONSE=$(curl -s -X POST https://oauth2.googleapis.com/token \
        -d "code=$code" \
        -d "client_id=$client_id" \
        -d "client_secret=$client_secret" \
        -d "redirect_uri=urn:ietf:wg:oauth:2.0:oob" \
        -d "grant_type=authorization_code")

    echo "$TOKEN_RESPONSE" | jq '.' > "$TMP_FILE"

    if [ -f "$TMP_FILE" ] && jq -e '.access_token' "$TMP_FILE" > /dev/null 2>&1; then
        echo "✅ Token obtido com sucesso!"

        EXPIRES_IN=$(jq -r '.expires_in' "$TMP_FILE")
        echo "⏰ Token válido por: $((EXPIRES_IN / 3600)) horas"

        jq --arg cid "$client_id" --arg cs "$client_secret" \
            '. + {client_id: $cid, client_secret: $cs}' \
            "$TMP_FILE" > "${TMP_FILE}.final"

        sudo mv "${TMP_FILE}.final" "$TOKEN_FILE"
        rm -f "$TMP_FILE"
    else
        echo "❌ Erro ao obter token:"
        echo "$TOKEN_RESPONSE" | jq '.'
        rm -f "$TMP_FILE"
        exit 1
    fi
}

main() {
    if [ ! -f "$CLIENT_FILE" ]; then
        setup_credentials
    else
        echo "✅ Credenciais já configuradas"
        echo "   Arquivo: $CLIENT_FILE"
        echo ""
        read -p "Reconfigurar? (s/N): " choice
        case "$choice" in
            s|S|sim|Sim)
                setup_credentials
                ;;
        esac
    fi
    
    generate_auth_url
    
    echo ""
    echo "=========================================="
    echo "✅ Configuração concluída!"
    echo "=========================================="
    echo ""
    echo "Próximos passos:"
    echo "1. Execute: bash gcal-sync-official.sh sync"
    echo "2. Configure automação se desejar"
    echo ""
}

main "$@"
