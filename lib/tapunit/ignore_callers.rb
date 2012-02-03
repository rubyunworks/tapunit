ignore = /(lib|bin)#{Regexp.escape(File::SEPARATOR)}tapunit/

$RUBY_IGNORE_CALLERS ||= []
$RUBY_IGNORE_CALLERS << ignore

