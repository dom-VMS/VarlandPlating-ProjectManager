class UsersController < ApplicationController
    def index
        current_user = User.find_by_id(session[:current_user_id])
        @users = User.all
    end

    def show
        @user = User.find(params[:id])
        @user_group = @user.user_groups   
        get_task_type_options_from_user_group
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
 
        if @user.save!
            flash[:success] = "User Added!"
            redirect_to @user
        else
            render 'new'
        end
    end

    def update
        @user = User.find(params[:id])
       
        if @user.update(user_params)
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
        params.require(:user).permit(:employee_number, :f_name, :l_name, :email, :hourly_rate, :password_digest, :password_confirmation)
      end

      def get_task_type_options_from_user_group
        @user_group.each do |user_group|
            @task_type_option = user_group.task_type_option
        end
      end
end
