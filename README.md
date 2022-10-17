# Silaeder Shower
Silaeder Shower mono repo. Website for managing presentation on conference organized by Silaeder school.
## Setup & environment

Clone or download the source files using the [Silaeder Shower](https://github.com/CoffeBee/SilaederShower/) repository. 

```shell
git clone https://github.com/CoffeBee/SilaederShower.git
cd SilaederShower
```

Create a dotenv file ( `.env` or `.env.development`) based on your environment) and config the following values.

```shell
# use your database server IP if needed
DATABASE_HOST=localhost
# database username (admin username, if serve localy)
DATABASE_USERNAME=podvorniy
# computer password, if database serve localy
DATABASE_PASSWORD=easy_pizzy_pwd
DATABASE_NAME=silaeder_shower
```

Create database on computer localy:
```shell
createdb silaeder_shower
```

Run migrations:
```shell
swift run Run migrate
```

Run server:
```shell
swift run Run serve --hostname 0.0.0.0 --port 8080
```
