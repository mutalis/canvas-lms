#
# Copyright (C) 2011 - 2014 Instructure, Inc.
#
# This file is part of Canvas.
#
# Canvas is free software: you can redistribute it and/or modify it under
# the terms of the GNU Affero General Public License as published by the Free
# Software Foundation, version 3 of the License.
#
# Canvas is distributed in the hope that it will be useful, but WITHOUT ANY
# WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
# A PARTICULAR PURPOSE. See the GNU Affero General Public License for more
# details.
#
# You should have received a copy of the GNU Affero General Public License along
# with this program. If not, see <http://www.gnu.org/licenses/>.
#

# Filters added to this controller apply to all controllers in the application.
# Likewise, all the methods added will be available for all controllers.

module Lti
  class SubstitutionsHelper
    def initialize(context, root_account, user)
      @context = context
      @root_account = root_account
      @user = user
    end

    def account
      @account ||=
          case @context
            when Account
              @context
            when Course
              @context.account
            else
              @root_account
          end
    end

    def current_lis_roles
      enrollments_to_lis_roles(course_enrollments + account_enrollments).join(',') || LtiOutbound::LTIRole::NONE
    end

    def concluded_lis_roles
      enrollments_to_lis_roles(concluded_course_enrollments).join(',') || LtiOutbound::LTIRole::NONE
    end

    def current_canvas_roles
      (lti_helper.course_enrollments.map(&:role) + lti_helper.account_enrollments.map(&:readable_type)).uniq.join(',')
    end

    def enrollments_to_lis_roles(enrollments)
      enrollments.map { |enrollment| Lti::LtiUserCreator::ENROLLMENT_MAP[enrollment.class] }.uniq
    end

    def course_enrollments
      return [] unless @context.is_a?(Course)
      @current_course_enrollments ||= @user.current_enrollments.find_all_by_course_id(@context.id)
    end

    def account_enrollments
      unless @current_account_enrollments
        @current_account_enrollments = []
        if @user && @context.respond_to?(:account_chain) && !@context.account_chain_ids.empty?
          @current_account_enrollments = @user.account_users.find_all_by_account_id(@context.account_chain_ids).uniq
        end
      end
      @current_account_enrollments
    end

    def concluded_course_enrollments
      @concluded_course_enrollments ||=
          @context.is_a?(Course) ? @user.concluded_enrollments.find_all_by_course_id(@context.id) : []
    end

    def currently_active_in_course?
      course_enrollments.any? { |membership| membership.state_based_on_date == :active }
    end

    def enrollment_state
      currently_active_in_course? ? LtiOutbound::LTIUser::ACTIVE_STATE : LtiOutbound::LTIUser::INACTIVE_STATE
    end
  end
end