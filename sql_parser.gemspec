# -*- encoding: utf-8 -*-
$:.push File.expand_path("../lib", __FILE__)

Gem::Specification.new do |s|
  s.name        = "sql_parser"
  s.version     = "0.0.1"
  s.authors     = ["Jingwen Owen Ou"]
  s.email       = ["jingweno@gmail.com"]
  s.homepage    = "https://github.com/jingweno/sql_parser"
  s.summary     = %q{A Ruby SQL parser based on Treetop.}
  s.description = %q{A Ruby SQL parser based on Treetop.}

  s.rubyforge_project = "."

  s.files         = `git ls-files`.split("\n")
  s.test_files    = `git ls-files -- {test,spec,features}/*`.split("\n")
  s.executables   = `git ls-files -- bin/*`.split("\n").map{ |f| File.basename(f) }
  s.require_paths = ["lib"]

  s.add_development_dependency "rspec"
  s.add_runtime_dependency "treetop"
end
