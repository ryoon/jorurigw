module System::Admin::GroupHistoryRelsHelper

  def get_previous_groups_rels(_group_id)
    _previous_groups = []
    _conditions = "current_group_id = #{_group_id}"
    _history_rels = System::GroupHistoryRel.find(:all ,:conditions=>_conditions , :order=>"previous_group_id ASC")

    _history_rels.each do | _rel |
      if _rel.previous_group_id
        _previous_group = System::Group.find(_rel.previous_group_id)
        _previous_groups << _previous_group
      end
    end
    return _previous_groups
  end

end
