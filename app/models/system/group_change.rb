class System::GroupChange < ActiveRecord::Base
  include System::Model::Base
  include System::Model::Tree
  include System::Model::Base::Config

  def self.check_sequence(latest=nil,process=nil)
    return false if latest.blank?
    return false if process.blank?
    case process
      when 'prepare'
        return true
      when 'updates'
        return false if latest.state.to_i > 8
        return true
      when 'reflects'
        return false if latest.state.to_i <2
        return false if latest.state.to_i > 8
        return true
      when 'history_temporaries'
        return false if latest.state.to_i <3
        return false if latest.state.to_i > 8
        return true
      when 'set_pickup'
        return false if latest.state.to_i <3
        return false if latest.state.to_i > 8
        return true
      when 'ldap'
        return false if latest.state.to_i <5
        return false if latest.state.to_i > 8
        return true
      when 'pickup'
        return false if latest.state.to_i <6
        return false if latest.state.to_i > 8
        return true
      when 'temporaries'
        return false if latest.state.to_i <7
        return false if latest.state.to_i > 8
        return true
      when 'fixed'
        return false if latest.state.to_i <7
        return false if latest.state.to_i > 9
        return true
      when 'csv'
        return false if latest.state.to_i <9
        return true
      when 'deletes'
        return false if latest.state.to_i <10
        return true
      else
        return false
    end
  end

  def self.make_record(latest=nil,process=nil,target_at=nil)
    return false if process.blank?
    case process
      when 'prepare'
        System::GroupChange.truncate_table
        item = System::GroupChange.new
        item.state = '1'
        item.save
        return
      when 'updates'
        if latest.blank?
          item = System::GroupChange.new
          item.state = '2'
          item.save
        else
          if latest.state == '2'
            item = System::GroupChange.new.find(latest.id)
            item.state = '2'
            item.updated_at = Time.now
            item.save
          else
            item = System::GroupChange.new
            item.state = '2'
            item.save
          end
        end
        return
      when 'reflects'
        if latest.blank?
          item = System::GroupChange.new
          item.state = '3'
          item.save
        else
          if latest.state == '3'
            item = System::GroupChange.new.find(latest.id)
            item.state = '3'
            item.updated_at = Time.now
            item.save
          else
            item = System::GroupChange.new
            item.state = '3'
            item.save
          end
        end
        return
      when 'history_temporaries'
        if latest.blank?
          item = System::GroupChange.new
          item.state = '4'
          item.save
        else
          if latest.state == '4'
            item = System::GroupChange.new.find(latest.id)
            item.state = '4'
            item.updated_at = Time.now
            item.save
          else
            item = System::GroupChange.new
            item.state = '4'
            item.save
          end
        end
        return
      when 'set_pickup'
        if latest.blank?
          item = System::GroupChange.new
          item.state = '5'
          item.save
        else
          if latest.state == '5'
            item = System::GroupChange.new.find(latest.id)
            item.state = '5'
            item.updated_at = Time.now
            item.save
          else
            item = System::GroupChange.new
            item.state = '5'
            item.save
          end
        end
        return
      when 'ldap'
        if latest.blank?
          item = System::GroupChange.new
          item.state = '6'
          item.save
        else
          if latest.state == '6'
            item = System::GroupChange.new.find(latest.id)
            item.state = '6'
            item.updated_at = Time.now
            item.save
          else
            item = System::GroupChange.new
            item.state = '6'
            item.save
          end
        end
        return
      when 'pickup'
        if latest.blank?
          item = System::GroupChange.new
          item.state = '7'
          item.target_at  = target_at
          item.save
        else
          if latest.state == '7'
            item = System::GroupChange.new.find(latest.id)
            item.state = '7'
            item.target_at  = target_at
            item.updated_at = Time.now
            item.save
          else
            item = System::GroupChange.new
            item.state = '7'
            item.target_at  = target_at
            item.save
          end
        end
        return
      when 'temporaries'
        if latest.blank?
          item = System::GroupChange.new
          item.state = '8'
          item.save
        else
          if latest.state == '8'
            item = System::GroupChange.new.find(latest.id)
            item.state = '8'
            item.updated_at = Time.now
            item.save
          else
            item = System::GroupChange.new
            item.state = '8'
            item.save
          end
        end
        return
      when 'fixed'
        if latest.blank?
          item = System::GroupChange.new
          item.state = '9'
          item.save
        else
          if latest.state == '9'
            item = System::GroupChange.new.find(latest.id)
            item.state = '9'
            item.updated_at = Time.now
            item.save
          else
            item = System::GroupChange.new
            item.state = '9'
            item.save
          end
        end
        return
      when 'csv'
        if latest.blank?
          item = System::GroupChange.new
          item.state = '10'
          item.save
        else
          if latest.state == '10'
            item = System::GroupChange.new.find(latest.id)
            item.state = '10'
            item.updated_at = Time.now
            item.save
          else
            item = System::GroupChange.new
            item.state = '10'
            item.save
          end
        end
        return
      when 'deletes'
        if latest.blank?
          item = System::GroupChange.new
          item.state = '11'
          item.save
        else
          if latest.state == '11'
            item = System::GroupChange.new.find(latest.id)
            item.state = '11'
            item.updated_at = Time.now
            item.save
          else
            item = System::GroupChange.new
            item.state = '11'
            item.save
          end
        end
        return
      else
        return
    end
  end

  def self.truncate_table
    connect = self.connection()
    truncate_query = "TRUNCATE TABLE `system_group_changes` ;"
    connect.execute(truncate_query)
  end
end
