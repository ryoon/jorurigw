class Gw::Admin::PrefDirectorsController < ApplicationController
  include System::Controller::Scaffold

  def index
    @counts1 = ""
    @counts2 = ""
    counts2 = ""

    case params[:init]
    when  'clear_all'
      @counts1 = initial_clear_all
    when  'init_setup'
      counts2  = init_datas
      @counts2 = counts2.join(' / ')
    end
  end

  def initial_clear_all
      Gw::PrefDirector.truncate_table
      return [Gw::PrefDirector.count(:all)]
  end

  def init_datas
    Gw::PrefDirector.truncate_table

    counts=[]

    cgu_cond =  "system_users.state='enabled' and system_groups.state='enabled' "
    cgu_cond << "  and system_users_custom_groups.icon < 7  and system_custom_groups.id > 227 and system_custom_groups.id < 241 "
    cgu_order = "system_groups.sort_no , system_users_custom_groups.sort_no"
    cgu_joins = " left join system_users on system_users.id = system_users_custom_groups.user_id "
    cgu_joins << " left join system_custom_groups on system_custom_groups.id = system_users_custom_groups.custom_group_id "
    cgu_joins << " left join system_users_groups on system_users_groups.user_id = system_users_custom_groups.user_id "
    cgu_joins << " left join system_groups on system_users_groups.group_id = system_groups.id "
    cgu_users = System::UsersCustomGroup.find(:all ,:conditions=>cgu_cond , :order=>cgu_order ,:joins=>cgu_joins)
    counts[0]=cgu_users.size
    counts[1]=0
    counts[2]=0
    counts[3]=0
    return counts if cgu_users.size==0

    cgu_users.each do |u|
      user = System::User.find_by_id(u.user_id)
      if user.blank?
        counts[2]=counts[2]+1
        next
      end
      ug_cond   = "user_id=#{user.id} and end_at is null"
      ug_order  = "user_id, job_order"
      users_group   = System::UsersGroup.find(:first , :conditions=>ug_cond , :order=>ug_order)
      if users_group.blank?
        counts[2]=counts[2]+1
        next
      end
      group = System::Group.find_by_id(users_group.group_id)
      if group.blank?
        counts[2]=counts[2]+1
        next
      end
      parent_group = System::Group.find_by_id(group.parent_id)
      if parent_group.blank?
        counts[2]=counts[2]+1
        next
      end
      custom_group = System::CustomGroup.find_by_id(u.custom_group_id)
      if custom_group.blank?
        counts[2]=counts[2]+1
        next
      end
      if user.offitial_position == '知事' or user.offitial_position == '副知事' or user.offitial_position == '政策監'
        counts[3]=counts[3]+1
        next
      end

      temp_title = group.name
      temp_title = temp_title.to_s + user.offitial_position.to_s
      director = Gw::PrefDirector.new
      director.parent_gid     = parent_group.id
      director.parent_g_code  = parent_group.code
      director.parent_g_name  = parent_group.name
      director.parent_g_order = parent_group.sort_no
      director.gid            = group.id
      director.g_code         = group.code
      director.g_name         = group.name
      director.g_order        = group.sort_no
      director.uid            = user.id
      director.u_code         = user.code
      director.u_lname        = ''
      director.u_lname        = user.offitial_position if u.sort_no==10
      director.u_name         = user.name
      director.u_order        = u.sort_no
      director.title          = u.title
      director.state          = 'off'
      director.save(false)
      counts[1]= counts[1] + 1
    end
    return counts
  end

end
