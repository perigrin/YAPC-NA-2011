#!/bin/sh -x
rsync -avz --delete ./actdocs/ act:/home/apache/htdocs/conferences-test/actdocs/yn2011/
rsync -avz --delete ./wwwdocs/ act:/home/apache/htdocs/conferences-test/wwwdocs/yn2011/
