# frozen_string_literal: true

require 'mkmf'

system_found = have_library('chdb') && have_header('chdb.h')

unless system_found
  abort "chdb.h or chdb library not found! Please install chdb development files.\n" \
        "You can try installing with: gem install chdb -- --with-opt-dir=/usr/local/lib \n" \
        'Or any other path that contains chdb.h and libchdb.so'
end

$srcs = Dir['*.c'] + ['chdb.c'] # rubocop:disable Style/GlobalVars

if RbConfig::CONFIG['GCC'] == 'yes'
  $CFLAGS << ' -Wno-declaration-after-statement' # rubocop:disable Style/GlobalVars
  $CFLAGS = $CFLAGS.gsub(/-Wno-self-assign|-Wno-parentheses-equality|-Wno-constant-logical-operand/, '') # rubocop:disable Style/GlobalVars
end

create_makefile('chdb/chdb')
