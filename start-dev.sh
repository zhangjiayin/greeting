#!/bin/sh
# NOTE: mustache templates need \ because they are not awesome.
exec erl -pa ebin edit deps/*/ebin rabbitmq-client/ebin/ -boot start_sasl \
    -sname "greeting_dev_app@yanli-OptiPlex-780" \
    -s greeting \
    -s reloader
