module Gw::PropOtherLimitsHelper

  def current_count_group_props_each(gid)
    joins = "left join gw_prop_others on gw_prop_others.id = gw_prop_other_roles.prop_id"
    cond_cars   = "gw_prop_other_roles.gid=#{gid} and  gw_prop_other_roles.auth='admin' and gw_prop_others.type_id=100 and gw_prop_others.delete_state=0 "
    count_cars   = Gw::PropOtherRole.count(:all,:conditions=>cond_cars , :joins => joins)
    cond_rooms   = "gw_prop_other_roles.gid=#{gid} and  gw_prop_other_roles.auth='admin' and gw_prop_others.type_id=200 and gw_prop_others.delete_state=0 "
    count_rooms  = Gw::PropOtherRole.count(:all,:conditions=>cond_rooms , :joins => joins)
    cond_others   = "gw_prop_other_roles.gid=#{gid} and  gw_prop_other_roles.auth='admin' and gw_prop_others.type_id=300 and gw_prop_others.delete_state=0 "
    count_others = Gw::PropOtherRole.count(:all,:conditions=>cond_others , :joins => joins)
    count_all = count_cars + count_rooms + count_others
    return [count_cars,count_rooms,count_others,count_all]
  end

end
