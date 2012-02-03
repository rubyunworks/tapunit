---
source:
- var
authors:
- name: trans
  email: transfire@gmail.com
copyrights:
- holder: Rubyworks
  year: '2012'
  license: BSD-2-Clause
replacements: []
alternatives: []
requirements:
- name: tapout
  version: ! '>= 0.3.0'
- name: test-unit
- name: detroit
  groups:
  - build
  development: true
- name: reap
  groups:
  - build
  development: true
- name: qed
  groups:
  - test
  development: true
- name: ae
  groups:
  - test
  development: true
dependencies: []
conflicts: []
repositories:
- uri: git://github.com/rubyworks/tapunit.git
  scm: git
  name: upstream
resources:
  home: http://rubyworks.github.com/tapunit
  docs: http://rubydoc.info/gems/tapunit
  code: http://github.com/rubyworks/tapunit
  bugs: http://github.com/rubyworks/tapunit/issues
  mail: http://groups.google.com/group/rubyworks-mailinglist
extra: {}
load_path:
- lib
revision: 0
summary: TAP-Y/J report formats for Test::Unit 2.x
title: TapUnit
version: 0.1.0
name: tapunit
description: ! 'TapUnit provides a TAP-Y/J report format for Test::Unit 2.x suitable
  for use

  with TAP-Y/J consumers like TAPOUT.'
organization: rubyworks
date: '2012-02-02'
