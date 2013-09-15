#tmp
module ActiveRecord::ConnectionAdapters::SchemaStatements
  def load_fixture(fixture, dir = "test/fixtures")
    require "active_record/fixtures"
    Fixtures.create_fixtures(dir, fixture)
  end
end

#def embed_file(file_name)
#  " !binary |\n" + Base64.encode64(File.read("#{RAILS_ROOT}/test/fixtures/#{file_name}")).gsub(/^/, '    ')
#end
#
#class Fixture
#  def value_list
#    columns = @class_name.constantize.columns.inject({}) {|h, c| h[c.name] = c; h }
#    @fixture.map do |k, v| 
#      ActiveRecord::Base.connection.quote(v, columns[k]).gsub('\\n', "\n").gsub('\\r', "\r")
#    end.join(", ")
#  end
#end

module ActiveRecord
  # テーブルロック
  module TableLocking
    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      def lock_table(*args)
        begin
          options = args.extract_options!
          target = get_lock_target(args, options)
          dump ["lock table... [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
          connection.execute("LOCK TABLES #{target};")
          dump ["lock table OK [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
          yield
        rescue Mysql::Error => e
          raise e
        ensure
          begin
            dump ["unlock table... [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
            connection.execute("UNLOCK TABLES;")
            dump ["unlock table OK [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
          rescue
            #dump "#{e.message}"
          end
        end
      end
      private
      def get_name(target)
        target.is_a?(String) ? target : Gw.tablize(target.class_name)
      end
      def get_lock_target(args, options={})
        name = ""
        if args.length == 0
          name = "#{get_name(self)} WRITE"
        elsif args.length == 1
          name = args[0]
        else
          args.each_with_index do |arg,idx|
            name += "#{get_name(arg)}"
            if idx % 2 == 1
              name += ", "
            else
              name += " "
            end
          end
          name.chop!
          name.chop!
        end
        return name
      end
    end
    def lock_table(*args)
      self.class.lock_table(*args)
    end
  end
  # 名前ロック
  module NameLocking
    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      def lock_name(*args)
        begin
          options = args.extract_options!
          target = get_lock_target(args, options)
          timeout = (options[:timeout] ? options[:timeout].to_i : 60)  # タイムアウト60秒
          dump ["get lock... [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
          res = connection.execute("SELECT GET_LOCK('#{target}', #{timeout});")
          unless exec_result_success?(res)
            raise ApplicationError.new("接続がタイムアウトしました。")
          end
          dump ["get lock OK [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
          yield
        ensure
          begin
            dump ["release lock... [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
            res = connection.execute("SELECT RELEASE_LOCK('#{target}');")
            dump ["release lock OK [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
          rescue
            #dump "#{e.message}"
          end
        end
      end
      private
      def get_name(target)
        target.is_a?(String) ? target : Gw.tablize(target.class_name)
      end
      def get_lock_target(args, options={})
        name = ""
        if args.length == 0
          name = get_name(self)
        else
          args.each do |arg|
            name += "#{get_name(arg)}-"
          end
          name.chop!
        end
        return name
      end
      def exec_result_success?(res)
        if res.class.to_s == 'Mysql::Result'
          ret = "0"
          res.each {|row| ret = row[0] }
          return false if ret == "0"
        end
        return true
      end
    end
    
    def lock_name(*args)
      self.class.lock_name(*args)
    end
  end
  # ファイルロック
  module FileLocking
    def self.included(base)
      base.extend(ClassMethods)
    end
    module ClassMethods
      def lock_file(*args)
        options = args.extract_options!
        target = get_lock_target(args, options)
        File.open(target, 'w') do |file|
          begin
            dump ["lock file... [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
            file.flock(File::LOCK_EX)
            dump ["lock file OK [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
            yield
          ensure
            dump ["unlock file... [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
            file.flock(File::LOCK_UN)
            dump ["unlock file OK [#{target}]", Time.now.strftime('%Y-%m-%d %H:%M:%S')]
          end
        end
      end
      private
      def get_name(target)
        target.is_a?(String) ? target : Gw.tablize(target.class_name)
      end
      def get_lock_target(args, options={})
        name = ""
        if args.length == 0
          name = get_name(self)
        else
          name = args.map{|x| get_name(x)}.join("-")
        end
        return "#{RAILS_ROOT}/tmp/lock/#{name}.lock"
      end
    end
    def lock_file(*args)
      self.class.lock_file(*args)
    end
  end
end

module ActiveRecord
  module ConnectionAdapters
    class MysqlAdapter
      # BEGIN/COMMIT/ROLLBACK無効化
      def begin_db_transaction
      end
      def commit_db_transaction
      end
      def rollback_db_transaction
      end
    end
  end
  # ロック機能インクルード
  Base.class_eval do
    include TableLocking, NameLocking, FileLocking
  end
end
