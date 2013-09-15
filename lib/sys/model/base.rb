module Sys::Model::Base

  def self.included(mod)
    mod.set_table_name mod.to_s.underscore.gsub('/', '_').downcase.pluralize
  end

  def locale(name)
    label = I18n.t name, :scope => [:activerecord, :attributes, self.class.to_s.underscore]
    return label =~ /^translation missing:/ ? name.to_s.humanize : label
  end

  def save_with_direct_sql #TODO
    quote = Proc.new{|v| self.class.connection.quote(v)}

    table = self.class.table_name
    sql = "INSERT INTO #{table} ("
    sql += self.class.column_names.sort.join(',')
    sql += ") VALUES ("

    self.class.column_names.sort.each_with_index do |name, i|
      sql += ',' if i != 0
      value = send(name)
      if value == nil
        sql += 'NULL'
      elsif value.class == Time
        sql += "'#{value.strftime('%Y-%m-%d %H:%M:%S')}'"
      else
        sql += quote.call(value)
      end
    end

    sql += ")"

    self.class.connection.execute(sql)
    rs = self.class.connection.execute("SELECT LAST_INSERT_ID() AS id FROM #{table}")
    return rs.fetch_row[0]
  end
end
