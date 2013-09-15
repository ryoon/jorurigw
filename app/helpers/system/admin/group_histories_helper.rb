module System::Admin::GroupHistoriesHelper

  def group_select_tree( _select_version_id = nil ,_notall = nil)
    if _select_version_id.blank?
      _version_id = System::GroupVersion.get_current_group_version_id
    else
      _version_id = _select_version_id
    end

    _groups = []
    if _notall == nil
      _groups << ['すべて' , "all"]
    end

    _dept_conditions =  "state = 'enabled'"
    _dept_conditions << " and level_no = 2"
    _dept_conditions << " and parent_id = 1"
    _dept_conditions << " and version_id = #{_version_id}"
    _dep_order = "code ASC"
    _departments = System::Group.find(:all , :conditions => _dept_conditions ,:order => _dep_order )

    _departments.each do | _dep |
        _groups << [  _dep[:name] , _dep.id ]
        _sec_conditions =  "state = 'enabled'"
        _sec_conditions << " and level_no = 3"
        _sec_conditions << " and parent_id = #{_dep.id}"
        _sec_conditions << " and version_id = #{_version_id}"
        _sec_order = "code ASC"
        _sections = System::Group.find(:all , :conditions => _sec_conditions ,:order => _sec_order )

        _sections.each do | _sec |
            _groups << [ ' -- '+_sec[:name] , _sec.id ,]
        end
    end
    return _groups
  end

  def group_compare( _currents , _nexts , _group_id={} , _next_version={} )
    if _currents.blank?
      _count_current_max = 0
    else
      _count_current_max = _currents.size
    end
    if _nexts.blank?
      _count_next_max    = 0
    else
      _count_next_max  = _nexts.size
    end
    if _group_id.blank?
      _select_group = nil
    else
      _select_group = System::Group.find(_group_id)
    end

    _count_current = 0
    _count_next    = 0
    _rows= []


    if !(_group_id.blank?)
      if _select_group.level_no == 3
        _next_conditions = "code = '#{_select_group.code}' and version_id = #{_next_version.id} "
        _next_group = System::Group.find(:all ,:conditions => _next_conditions )
        if _next_group.blank?
           _set_current( _rows , _select_group )
            _count_current = _count_current + 1
        else
          if _currents[_count_current][:name] == _next_group[0][:name]
            _set_both_same( _rows , _select_group ,_next_group[0] )
          else
            _set_both_othername( _rows , _select_group ,_next_group[0] )
          end
        end
        return _rows
      end
    end

    if !(_group_id.blank?)
        _next_conditions = "code = '#{_select_group.code}' and version_id = #{_next_version.id} "
        _next_group = System::Group.find(:all ,:conditions => _next_conditions )
        if _currents[_count_current][:code] == _next_group[0].code
          if _currents[_count_current][:name] == _next_group[0].name
              _set_both_same( _rows , _currents[_count_current] , _next_group[0] )
          else
              _set_both_othername( _rows , _currents[_count_current] ,_next_group[0] )
          end

            _next_groups = System::Group.get_group_tree( "#{_next_version.id}" , "#{_next_group[0].id}")
            _count_current = 1
            _count_next    = 1
            _count_next_max  = _next_groups.size
            while( ( _count_current < _count_current_max ) && ( _count_next < _count_next_max ) )
              if _currents[_count_current][:code] == _next_groups[_count_next][:code]
                  if _currents[_count_current][:name] == _next_groups[_count_next][:name]
                      _set_both_same( _rows , _currents[_count_current] ,_next_groups[_count_next] )
                  else
                      _set_both_othername( _rows , _currents[_count_current] ,_next_groups[_count_next] )
                  end
                  _count_current = _count_current + 1
                  _count_next    = _count_next + 1
              else
                if _currents[_count_current][:code] < _next_groups[_count_next][:code]
                    _set_current( _rows , _currents[_count_current] )
                    _count_current = _count_current + 1
                else
                    _set_next( _rows , _next_groups[_count_next] )
                    _count_next    = _count_next + 1
                end
              end
            end

            if _count_current < _count_current_max
              while _count_current < _count_current_max
                  _set_current( _rows , _currents[_count_current] )
                  _count_current = _count_current + 1
              end
            else
              while _count_next < _count_next_max
                  _set_next( _rows , _next_groups[_count_next] )
                  _count_next    = _count_next + 1
              end
            end

        else

          _del_parent_id = _currents[_count_current][:id]
          _set_current( _rows , _currents[_count_current] )
          _count_current = _count_current + 1

          while ( _count_current < _count_current_max )
            _set_current( _rows , _currents[_count_current] )
            _count_current = _count_current + 1
          end
        end
      return _rows
    end

    while ( ( _count_current < _count_current_max ) && ( _count_next < _count_next_max ) )
      if _currents[_count_current][:level_no] == 2

        if  _nexts[_count_next][:level_no] == 2
          if _currents[_count_current][:code] == _nexts[_count_next][:code]
              if _currents[_count_current][:name] == _nexts[_count_next][:name]

                  _set_both_same( _rows , _currents[_count_current] ,_nexts[_count_next] )
              else

                  _set_both_othername( _rows , _currents[_count_current] ,_nexts[_count_next] )
              end
              _count_current = _count_current + 1
              _count_next    = _count_next + 1
          else
            if _currents[_count_current][:code] < _nexts[_count_next][:code]

                _del_parent_id = _currents[_count_current][:id]
                _set_current( _rows , _currents[_count_current] )
                _count_current = _count_current + 1

                while ( (_count_current < _count_current_max) && (_currents[_count_current][:parent_id] == _del_parent_id) )
                  _set_current( _rows , _currents[_count_current] )
                  _count_current = _count_current + 1
                end
            else

                _add_parent_id = _nexts[_count_next][:id]
                _set_next( _rows , _nexts[_count_next] )
                _count_next    = _count_next + 1

                while ( ( _count_next < _count_next_max ) && ( _nexts[_count_next][:parent_id] == _add_parent_id ))
                _set_next( _rows , _nexts[_count_next] )
                _count_next    = _count_next + 1
                end
            end
          end
        else

          _set_next( _rows , _nexts[_count_next] )
          _count_next    = _count_next + 1
        end
      else
        if _currents[_count_current][:code] == _nexts[_count_next][:code]
            if _currents[_count_current][:name] == _nexts[_count_next][:name]

                _set_both_same( _rows , _currents[_count_current] ,_nexts[_count_next] )
            else

                _set_both_othername( _rows , _currents[_count_current] ,_nexts[_count_next] )
            end
            _count_current = _count_current + 1
            _count_next    = _count_next + 1
        else
          if _currents[_count_current][:code] < _nexts[_count_next][:code]

              _set_current( _rows , _currents[_count_current] )
              _count_current = _count_current + 1
          else

              _set_next( _rows , _nexts[_count_next] )
              _count_next    = _count_next + 1
          end
        end
      end
    end

    if _count_current >= _count_current_max
      while _count_next < _count_next_max
          _set_next( _rows , _nexts[_count_next] )
          _count_next    = _count_next + 1
      end
    else
      while _count_current < _count_current_max
          _set_current( _rows , _currents[_count_current] )
          _count_current = _count_current + 1
      end
    end
    return _rows
  end

  def _get_group_history_rel_status(_group_id)
    _history_rel_counts = System::GroupHistoryRel.count(:all,:conditions=>"current_group_id = #{_group_id} ")
    if _history_rel_counts > 1
      _history_rel_status = '統合'
    else
      if _history_rel_counts == 0
        _history_rel_status = nil
      else
        _history_rel_status = '継続'
      end
    end
    return _history_rel_status
  end

  def _set_both_same( _row , _current , _next)
    _history_rel_status = _get_group_history_rel_status(_next[:id])
    _row << [{
      :c_level => _current[:level_no] ,
      :c_id   => _current[:id] ,
      :c_code => _current[:code] ,
      :c_name => _current[:name] ,
      :c_state => '変更なし',
      :n_level => _next[:level_no] ,
      :n_id   => _next[:id] ,
      :n_code => _next[:code] ,
      :n_name => _next[:name],
      :n_state => nil,
      :n_rel_status => _history_rel_status
      }]
  end

  def _set_both_othername( _row , _current , _next)
    _history_rel_status = _get_group_history_rel_status(_next[:id])
    _row << [{
      :c_level => _current[:level_no] ,
      :c_id   => _current[:id] ,
      :c_code => _current[:code] ,
      :c_name => _current[:name] ,
      :c_state => '名称変更',
      :n_level => _next[:level_no] ,
      :n_id   => _next[:id] ,
      :n_code => _next[:code] ,
      :n_name => _next[:name],
      :n_state => nil,
      :n_rel_status => _history_rel_status
      }]
  end

  def _set_current( _row , _current )
    _row << [{
      :c_level => _current[:level_no] ,
      :c_id   => _current[:id] ,
      :c_code => _current[:code] ,
      :c_name => _current[:name] ,
      :c_state => '廃止',
      :n_level => nil ,
      :n_id   => nil ,
      :n_code => nil ,
      :n_name => nil ,
      :n_state => nil,
      :n_rel_status => nil
      }]
  end

  def _set_next( _row , _next)
    _history_rel_status = _get_group_history_rel_status(_next[:id])
    _row << [{
      :c_level   => nil ,
      :c_id   => nil ,
      :c_code => nil ,
      :c_name => nil ,
      :c_state => nil,
      :n_level => _next[:level_no] ,
      :n_id   => _next[:id] ,
      :n_code => _next[:code] ,
      :n_name => _next[:name] ,
      :n_state => '新設',
      :n_rel_status => _history_rel_status
      }]
  end
end