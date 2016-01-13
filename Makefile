PRJ=Base:System
PKG=brp-check-suse

all:

package:
	@if test -d $(PKG); then cd $(PKG) && osc up && cd -; else osc co -c $(PRJ) $(PKG); fi
	@./mkchanges | tee $(PKG)/.changes
	@test ! -s $(PKG)/.changes || git push
	@test -z "`git rev-list remotes/origin/master..master`" || { echo "unpushed changes"; exit 1; }
	@f=(*xz); test -z "$f" || /bin/rm -vi *.xz
	@./mktar
	@mv *xz $(PKG)

.PHONY: all package
