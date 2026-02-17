if status --is-interactive
    setenv SSH_ENV $HOME/.ssh/environment

    function start_agent
        echo "Initializing new SSH agent ..."
        ssh-agent -c | sed 's/^echo/#echo/' > $SSH_ENV
        echo "succeeded"
        chmod 600 $SSH_ENV 
        . $SSH_ENV > /dev/null
        ssh-add
    end

    function test_identities
        ssh-add -l | grep "The agent has no identities" > /dev/null
        if [ $status -eq 0 ]
            ssh-add
            if [ $status -eq 2 ]
                start_agent
            end
        end
    end

    function handle_ssh
        if [ -n "$SSH_AGENT_PID" ] 
            ps -ef | grep $SSH_AGENT_PID | grep ssh-agent > /dev/null
            if [ $status -eq 0 ]
                test_identities
            end  
        else
            if [ -f $SSH_ENV ]
                . $SSH_ENV > /dev/null
            end  
            ps -ef | grep $SSH_AGENT_PID | grep -v grep | grep ssh-agent > /dev/null
            if [ $status -eq 0 ]
                test_identities
            else 
                start_agent
            end  
        end
    end

    function handle_npm_env
        setenv NPM_DIR $HOME/.npm-global
        if not test -d $NPM_DIR
            echo "Could not find .npm-global on home directory, creating it!"
            mkdir $HOME/.npm-global
            npm config set prefix '~/.npm-global'
        end
    end

    handle_ssh
    handle_npm_env
end

bass source '/opt/google-cloud-cli/path.bash.inc'
bass source '/opt/google-cloud-cli/completion.bash.inc'

set PATH $PATH $HOME/.local/bin /home/nicolas/go/bin
set PATH $PATH $HOME/.nvm/versions/node/v22.17.0/bin/npm

