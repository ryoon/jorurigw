# Where Builder for ActiveRecord
#
# (c) 2005-2006 Ezra Zygmuntovic and Jens-Christian Fischer
# distributed under the same license as Ruby On Rails
#
# Version 0.2, 2.1.2006
# - removed Where class
# - added Ezra's Cond Class
# - find_with_conditions uses Cond class
#
# Version 0.2.1, 25.5.2006
# - fixed problem with options hash not being passed to find (iktorn)
# - fixed SQL problem, when conditions were empty (iktorn)
#

module ActiveRecord #:nodoc:
    class Base
        class << self # Class methods
            
            # allows you to use the following block form for find:
            # Model.find_with_conditons( :all, :limit => ..., :order => ... ) do 
            #   name 'like', 'fischer' 
            #   date 'between', date1, date2 
            # end
            #
            # the method passes all arguments to the ActiveRecord::find method and adds
            # the :conditions => .... clause to the options hash
            
            
            def find_with_conditions(*args, &block)
                cond = InVisible::Cond.new(&block)
                
                #where ||= InVisible::Where.new
                #yield where
                options = args.last.is_a?(Hash) ? args.pop : {} 
                conditions = cond.where
                options[:conditions]= conditions unless conditions.first.empty?
                self.find( args.first, options )
            end
            
            def get_sql(*args)
                options = extract_options_from_args!(args)

                # Inherit :readonly from finder scope if set.  Otherwise,
                # if :joins is not blank then :readonly defaults to true.
                unless options.has_key?(:readonly)
                    if scoped?(:find, :readonly)
                        options[:readonly] = scope(:find, :readonly)
                    elsif !options[:joins].blank?
                        options[:readonly] = true
                    end
                end
            
                case args.first
                    when :first
                        get_sql(:all, options.merge(options[:include] ? { } : { :limit => 1 })).first
                    when :all
                        sql = construct_finder_sql(options)
                    else
                        sql = ""
                    end
                return sql
            end
            
            # returns the maximal estimated cost for the query
            # works only in Postgres to my knowledge
            def explain( query )
                sql = "explain #{query}"
                rows = self.connection.select_all(sql) rescue logger.warn( "explain failed" )
                return rows.first["QUERY PLAN"].split("=")[1].split(" ")[0].split("..")[1] rescue "0"
            end
            
        end
    end
end

module InVisible
    
    # Original Cond class by Ezra Zygmuntovic
    # Utility class to dynamically create the where clause
    # for a rails find method. 
    
    # Uses a block to initialize the condition:
    # c = InVisible::Cond.new do
    #    month '<=', 11
    #    year '=', 2005
    #    name 'LIKE', 'ruby%'
    #  end
    # 
    # c.where -> ["month <= ? and year = ? and name LIKE ?", 11, 2005, "ruby%"]
    # Lets say that you have this hash in your +params+ :
    # params = { :person => {:name => "dave" :city => "Yakima"}}
    #
    # c = InVisible::Cond.new do
    #    person '=', params[:person][:name]
    #    city   '=', params[:person][:city]
    # end
    # MyModel.find(:all, :conditions => c.where)
    #
    # or simpler:
    # MyModel.find_with_conditions( :all ) do
    #    person params[:person][:name]
    #    city   params[:person][:city]
    # end
    #
    # to include direct SQL, use like this:
    # c = InVisible::Cond.new do
    #   sql "hosts.id = logs.host_id and hosts.name", 'like', "123.23.45.67"
    # end
    # if a value needs to by typed (f.e. in Postgres: "ip < inet ?"), use a form of:
    # c = InVisible::Cond.new do
    #    ip '= inet', '123.34.56.78/24'
    # end
    #
    # to expand an existing condition, use the << method
    # c << ['age', '>', 30]
    
    
    class Cond

      def initialize(&block)
        @args = []
        instance_eval(&block) if block_given?
      end

      def method_missing(sym, *args)
          @args << [sym,args.flatten].flatten
      end
      
      def <<(*args)
         @args << [args.flatten].flatten
      end

      def where(args=@args)
          q = []
          ary = []
          args.each do |pair|
            iv = pair[1..99]
            unless iv.last.nil? || iv.last.to_s == ''
                if pair[0].to_s =~ /^sql.*/ then
                   pair[0] = iv.shift 
                end
                case iv.size
                when 0: 
                    q << "#{pair[0]}"   # the case when there is only one (sql) statements
                when 1:
      	            q << "#{pair[0]} = ?"
      	            ary << iv.last
      	        when 2:
      	            operator = iv[0]
      	            q << "#{pair[0]} #{operator} ?"
  	                ary << iv.last
  	            when 3:
  	                op = case iv[0]
                            when 'between': "between ? and ?"
                        end
                    q << "#{pair[0]} #{op}"
                    ary << iv[-2] << iv[-1]
  	            end 
      	    end
          end
          return [q.join(" and ")].concat(ary)
        
      end
    end
    
end

