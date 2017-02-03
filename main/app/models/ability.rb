# class Ability
#   include CanCan::Ability

#   def initialize(user)
#     user ||= User.new
#     if user.role.nil?
#       can :index, Welcome
#       # can :read, :allerros
#     else
#       user.role.permissions.each do |permission|
#         can permission.action.to_sym, permission.subject_class.constantize rescue nil
#       end
#     end
    
#   end
# end
