FROM bitwalker/alpine-elixir:1.5.2

MAINTAINER ElixirDrip "dev@elixirdrip.io"

ARG mix_env=prod
ARG https_port=4040
ARG http_port=4000
ARG epmd_port=4639
ARG app_version=0.1.0
ARG app_path=/opt/app/
ARG app_name=elixir_drip
ARG replace_os_vars=true

ENV TERM xterm
ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

ENV REFRESHED_AT 2017-12-16

ENV APP_PATH $app_path
ENV APP_NAME $app_name
ENV APP_VERSION $app_version
ENV HTTP_PORT $http_port
ENV HTTPS_PORT $https_port
ENV EPMD_PORT $epmd_port
ENV MIX_ENV $mix_env
ENV REPLACE_OS_VARS $replace_os_vars

RUN apk add --no-cache inotify-tools nodejs nodejs-npm
RUN mix archive.install https://github.com/phoenixframework/archives/raw/master/phx_new.ez --force

ADD . $APP_PATH/$APP_NAME

WORKDIR $APP_PATH/$APP_NAME

RUN rm -rf _build  \
    && rm -rf deps \
    && rm -rf logs \
    && cd apps/elixir_drip_web/assets \
    && ./node_modules/brunch/bin/brunch b -p \
    && cd $APP_PATH/$APP_NAME \
    && MIX_ENV=$MIX_ENV mix clean \
    && MIX_ENV=$MIX_ENV mix deps.get \
    && MIX_ENV=$MIX_ENV mix compile \
    && MIX_ENV=$MIX_ENV mix release --env=$MIX_ENV

EXPOSE $HTTP_PORT $HTTPS_PORT $EPMD_PORT

CMD trap exit TERM; $APP_PATH/$APP_NAME/_build/$MIX_ENV/rel/$APP_NAME/bin/$APP_NAME foreground & wait
