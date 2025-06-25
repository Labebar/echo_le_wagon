module UsersHelper
  def user_avatar_tag(user, options = {})
    css = options[:class]
    if user.avatar&.key.present?
      cl_image_tag user.avatar.key, class: css
    else
      image_tag("default-avatar.png", class: css)
    end
  end
end
