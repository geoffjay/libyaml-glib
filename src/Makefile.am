lib_LTLIBRARIES = libyaml-glib.la

VALASOURCES = libyaml-glib.vala error.vala buildable.vala builder.vala loader.vala writer.vala
libyaml_glib_la_SOURCES = $(VALASOURCES:.vala=.c) libyaml-glib-1.0.h
libyaml_glib_la_CPPFLAGS = $(LIBYAML_CFLAGS) $(GLIB_CFLAGS)
libyaml_glib_la_LIBADD = $(LIBYAML_LIBS) $(GLIB_LIBS)
libyaml_glib_la_LDFLAGS = -version-info 0:0:0 -release $(VERSION)

BUILT_SOURCES = vala-ccode vala-doc


$(DIST_SOURCES): vala-ccode

vala-ccode: $(VALASOURCES) libyaml-1.0.vapi workaround.vapi
	$(VALAC) -g --library libyaml-glib-1.0 -H libyaml-glib-1.0.h -C $(VALASOURCES) libyaml-1.0.vapi --pkg gmodule-2.0 workaround.vapi
	echo libyaml-1.0 > libyaml-glib-1.0.deps
	touch $@

if ENABLE_VALADOC
vala-doc: $(VALASOURCES) libyaml-1.0.vapi
	$(VALADOC) -o Documentation --package-name libyaml-glib-1.0 $(VALASOURCES) libyaml-1.0.vapi --pkg gmodule-2.0
	touch $@
else
vala-doc:
	mkdir -p Documentation
	touch $@
endif

vapi_DATA = libyaml-glib-1.0.vapi libyaml-glib-1.0.deps libyaml-1.0.vapi
vapidir=$(datadir)/vala/vapi
pkginclude_HEADERS = libyaml-glib-1.0.h \
                     $(top_srcdir)/libyaml/include/yaml.h

EXTRA_DIST = libyaml-1.0.vapi \
             workaround.vapi \
             $(VALASOURCES) \
             libyaml-glib-1.0.vapi \
             libyaml-glib-1.0.deps \
             vala-ccode \
             vala-doc \
             Documentation

DISTCLEANFILES = 

MAINTAINERCLEANFILES = $(VALASOURCES:.vala=.c) libyaml-glib-1.0.h \
                       libyaml-glib-1.0.vapi \
                       libyaml-glib-1.0.deps \
                       Documentation
