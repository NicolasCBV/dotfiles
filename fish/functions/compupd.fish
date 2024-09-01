function compupd --wraps='docker compose up -d' --description 'alias compupd=docker compose up -d'
  docker compose up -d $argv
        
end
