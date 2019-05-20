class UsersController < ApplicationController
  before_action :find_user, only: [:show, :edit, :update, :destroy]

  def index
    if search_params[:search]
      @users = User.search(search_params[:search])
      if @users.nil? || @users.empty?
        @users = User.all.order(:employee_number)
        flash.now[:notice] = "Sorry, we couldn't find what you are searching for."
      end
    else
      @users = User.all.order(:employee_number)
    end
  end

  def show
    @can_edit = verify_if_current_user_can_edit(@user, current_user)
    @user_group = @user.user_groups.includes(:task_type_option) 
    get_task_type_options_from_user_group
    @task = Task.get_all_tasks_assigned_to_user(@user)
    @task_types = TaskType.where(id: @task.pluck(:task_type_id).uniq).order(:parent_id)
    @pagy_logged_labors, @logged_labors = pagy(@user.logged_labors.order('updated_at DESC'), page_param: :page_recent_activity, params: { active_tab: 'logged_labors' })
  end
  
  def new
    @user = User.new
  end

  def edit
    unless verify_if_current_user_can_edit(@user, current_user)
      respond_to do |format|
        format.html { redirect_to user_path(@user) }
      end
    end
    @user_group = @user.user_groups.includes(:task_type_option)   
    get_task_type_options_from_user_group
  end

  def create
    @user = User.new(user_params)
    respond_to do |format|
      if @user.save
        # Tell the UserMailer to send a welcome email after save
        UserMailer.with(user: @user).welcome_email.deliver_now #deliver_now!

        format.html { redirect_to(@user, notice: 'User was successfully created.') }
        format.json { render json: @user, status: :created, location: @user }
      else
        format.html { render action: 'new' }
        format.json { render json: @user.errors, status: :unprocessable_entity }
      end
    end
  end

  def update
    unless verify_if_current_user_can_edit(@user, current_user)
      respond_to do |format|
        flash[:error] = "You are not permitted to update this user's info."
        format.html { redirect_to user_path(@user) }
      end
    end
    
    if @user.update(user_params)
      redirect_to @user
    else
      render 'edit'
    end
  end

  def destroy
    @user.destroy
    
    redirect_to users_path
  end

  private
    def user_params
      params.require(:user).permit(:employee_number, :f_name, :l_name, :email, :hourly_rate, :password, :password_confirmation)
    end

    def search_params
      params.permit(:search)
    end

    def get_task_type_options_from_user_group
      @user_group.each do |user_group|
          @task_type_option = user_group.task_type_option
      end
    end

  protected
    # Grabs user based on id
    def find_user
      @user = User.find(params[:id])
    end

    # Verifies if the current_user may edit a given @user information
    def verify_if_current_user_can_edit(user, current_user)
      return true if (current_user == user) # If current_user is @user, they may edit @user.
      return false if current_user&.task_type_options.nil? #If current_user has no roles, they may not edit @user.
      
      user_task_types = TaskType.find(user.task_type_options.pluck(:task_type_id)) #TaskTypes the user is assigned to.
      current_user_admin_task_types = TaskType.includes(:children).find(current_user.task_type_options.where(isAdmin: true).pluck(:task_type_id)) #TaskTypes where current_user is directly assigned as an admin.
      current_user_non_admin_task_types = TaskType.find(current_user.task_type_options.where(isAdmin: false).pluck(:task_type_id)) #TaskTypes where current_user is not assigned as an admin.
      
      # This process finds all TaskTypes where current_user is an admin, based on parent/child association.
      current_user_admin_task_types.each do |task_type|
        if task_type.children.any?
          (task_type.children.includes(:children)).each do |child|
            current_user_admin_task_types.append(child) unless (current_user_admin_task_types.any? {|task_type| task_type == child}) || (current_user_non_admin_task_types.any? {|unpermitted| unpermitted == child})
          end
        end
      end

      return current_user_admin_task_types.pluck(:id).any? {|admin_tt| user_task_types.pluck(:id).any?(admin_tt)} # Return true/false if there are any projects that overlap.

    end 
end
