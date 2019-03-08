class UsersController < ApplicationController
  before_action :find_user, only: [:show, :edit, :update]

    def index
      current_user = User.find_by_id(session[:current_user_id])
      if search_params[:search]
        @users = User.search(search_params[:search])
        if @users.nil? || @users.empty?
          @users = User.all.order(:employee_number)
          flash[:notice] = "Sorry, we couldn't find what you are searching for."
        end
      else
        @users = User.all.order(:employee_number)
      end

    end

    def show
      unless isAdmin? == true || current_user.id == @user.id
        respond_to do |format|
          flash[:error] = "Sorry, but you are not permitted to access this user's info."
          format.html { redirect_back(fallback_location: users_path) }
        end
      end
      @user_group = @user.user_groups   
      get_task_type_options_from_user_group
      task_type_ids = TaskType.get_task_types_assigned_to_user(@user)
      @task_types = TaskType.where(id: [task_type_ids])
      @task = Task.get_all_tasks_assigned_to_user(@user)
    end
    
    def new
      @user = User.new
    end

    def edit
      @user = User.find(params[:id])
      @user_group = @user.user_groups   
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
      @user = User.find(params[:id])
      
      if @user.update(edit_user_params)
        redirect_to @user
      else
        render 'edit'
      end
    end

    def destroy
      @user = User.find(params[:id])
      @user.destroy
      
      redirect_to users_path
    end

    private
      def user_params
        params.require(:user).permit(:employee_number, :f_name, :l_name, :email, :hourly_rate, :password, :password_confirmation)
      end

      def edit_user_params
        params.require(:user).permit(:employee_number, :f_name, :l_name, :email, :hourly_rate)
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
      def find_user
        @user = User.find(params[:id])
      end
end
