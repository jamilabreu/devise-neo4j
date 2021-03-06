require 'fileutils'

# mostly copied from neo4j/spec/spec_helper

EMBEDDED_DB_PATH = File.join(Dir.tmpdir, "neo4j-core-java")

I18n.enforce_available_locales = false


if RUBY_PLATFORM == 'java'
  require "neo4j-embedded/embedded_impermanent_session"

  # FIX for OpenSSL::Cipher::CipherError: Illegal key size:
  # http://stackoverflow.com/questions/14552303/opensslcipherciphererror-with-rails4-on-jruby
  java_import 'java.lang.ClassNotFoundException'

  begin
    security_class = java.lang.Class.for_name('javax.crypto.JceSecurity')
    restricted_field = security_class.get_declared_field('isRestricted')
    restricted_field.accessible = true
    restricted_field.set nil, false
  rescue ClassNotFoundException => e
    # Handle Mac Java, etc not having this configuration setting
    $stderr.print "Java told me: #{e}n"
  end
end

def create_session
  if RUBY_PLATFORM != 'java'
    create_server_session
  else
    create_embedded_session
  end
end

def create_embedded_session
  session = Neo4j::Session.open(:impermanent_db, EMBEDDED_DB_PATH, auto_commit: true)
  session.start
end

def create_server_session
  Neo4j::Session.open(:server_db, "http://localhost:7474")
end

FileUtils.rm_rf(EMBEDDED_DB_PATH)

Dir["#{File.dirname(__FILE__)}/shared_examples/**/*.rb"].each { |f| require f }

def delete_db
  Neo4j::Session.current._query('MATCH (n) OPTIONAL MATCH (n)-[r]-() DELETE n,r')
end

class ActiveSupport::TestCase
  setup do
    create_session unless Neo4j::Session.current
    delete_db
  end
end
