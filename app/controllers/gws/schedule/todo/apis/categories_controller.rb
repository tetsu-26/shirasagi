class Gws::Schedule::Todo::Apis::CategoriesController < ApplicationController
  include Gws::ApiFilter

  model Gws::Schedule::TodoCategory

  before_action :set_category

  private

  def set_category
    @categories = Gws::Schedule::TodoCategory.site(@cur_site).readable(@cur_user, site: @cur_site).tree_sort

    category_id = params.dig(:s, :category).presence
    @category = @model.where(id: category_id).first if category_id.present?
  end

  def parent_name
    return // unless @category
    /^#{::Regexp.escape(@category.name)}\//
  end

  public

  def index
    @multi = params[:single].blank?

    @items = @model.site(@cur_site).
      readable(@cur_user, site: @cur_site).
      search(params[:s]).
      where(name: parent_name).
      tree_sort
    @items = Kaminari.paginate_array(@items.to_a).page(params[:page]).per(50)
  end
end
