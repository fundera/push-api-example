
require 'fileutils'
require 'dbm'
require 'yaml'

require_relative 'model'

class Store
  DB_DIR = './db'

  def put(key, record)
    raise "expected a record of type @model.name" unless record.is_a?(@model)
    @db[key] = record.to_yaml
  end

  def get(key)
    s = @db[key]
    return nil if s.nil?
    YAML.load(s)
  end

  def all
    rs = []
    @db.each_pair do |key, record|
      rs << [key, YAML.load(record)]
    end
    rs.sort do |a, b|
      b[1].updated_at <=> a[1].updated_at
    end
  end

  def self.for(model, environment = 'development')
    raise 'expected a subclass of Model' unless model < Model
    dir = File.join(DB_DIR, environment.to_s)
    FileUtils.mkdir_p(dir)
    db = DBM.new(File.join(dir, model.name.downcase), 0o660, DBM::WRCREAT)
    begin
      yield Store.new(model, db)
    ensure
      db.close
    end
  end

  def self.delete_all(environment)
    dir = File.join(DB_DIR, environment.to_s)
    FileUtils.rm_rf(dir)
  end

  private

  def initialize(model, db)
    @model = model
    @db = db
  end
end
