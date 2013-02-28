#!/bin/sh
cd `dirname $0`
exec erl -pa $PWD/ebin $PWD/deps/*/ebin -boot start_sasl  -i rabbitmq-client/ebin/ -i rabbitmq-client/include -s greeting  -detached
