# stns-server
STNS server settings

## Setup
1. Create `stns.conf` file on `stns-server` directory.
    ```stns.conf
    port = 1104
    include = "/etc/stns/conf.d/*"
    
   # STNS server-client authentication (basic auth example)
    [basic_auth]
    user = "stnsuser"
    password = "stnspassword"
    ```
2. Create `.env` file on `stns-server` directory.
    ```.env
    CSV_URL="https://xxxxx.xxx/xxxxx.csv"
    ```
    This csv file should follow the format below:
    | Timestamp | Mail address | Username | Shell | Pubkey (vmlserver) | Pubkey (vmlbastion) |
    |:---:|:---:|:---:|:---:|:---:|:---:|
    | 20XX/01/01 00:00:00 | mail@xxxxx | user | bash | ssh-rsa AAAA... | ssh-ed25519 AAAA... |
  
    Using Google Forms, you can easily get this csv file and url.
3. Run scripts to add users.
    ```
    ./update-vmlserver.sh
    ./update-vmlbastion.sh
    ```
4. Run stns containers.
    ```
    sudo docker-compose up -d
    ```

## Add new user
1. Run scripts to add users.

    ```
    ./update-vmlserver.sh
    
    # or / and
    
    ./update-vmlbastion.sh
    ```
2. Restart stns containers.

    ```
    sudo docker-compose restart
    ```
