class WebsitesController < ApplicationController
  def new
    @website = Website.new
  end

  def create
    @website = Website.new(name: params[:website][:name], description: params[:website][:description])

    generated_content = WebsiteGeneratorService.generate_website(@website.description)
    if generated_content.nil?
      flash[:alert] = "Failed to generate website. Try again."
      render :new and return
    end

    generated_pages = generated_content["pages"].map do |page_data|
      Page.new(name: page_data["name"].underscore, content: page_data["content"])
    end

    @website.pages = generated_pages

    if @website.save
      redirect_to page_website_path(id: @website.id, page_name: 'home')
    else
      flash[:alert] = "Failed to save website."
      render :new
    end
  end

  def show
    @website = Website.find(params[:id])
  end

  def page
    @website = Website.find(params[:id])
    page_data = @website.pages.find { |page| page["name"].underscore == params[:page_name].underscore }
    navigation_links = @website.pages.map do |page|
      { "name" => page.name, "url" => page_website_path(id: @website.id, page_name: page.name) }
    end

    render html: render_page(page_data, navigation_links).html_safe
  end

  def edit_page
    @website = Website.find(params[:id])
    @page_data = @website.pages.find { |page| page["name"].underscore == params[:page_name].underscore }

    if @page_data.nil?
      redirect_to website_path(@website), alert: "Page not found."
      return
    end
  end

  def update_page
    @website = Website.find(params[:id])
    @page_data = @website.pages.find { |page| page.name.underscore == params[:page_name].underscore }
  
    if @page_data.nil?
      redirect_to website_path(@website), alert: "Page not found."
      return
    end
  
    # Update heading and description
    @page_data.content["heading"] = params[:heading]
    @page_data.content["description"] = params[:description]
  
    # Update sections with image upload handling
    updated_sections = []

    # params[:sections].values.each_with_index do |section_params, index|
    #   section = section_params
      # Handle image upload
      # if params[:sections]["#{index}"][:image].present?
      #   uploaded_image = params[:sections]["#{index}"][:image]
      #   image_blob = ActiveStorage::Blob.create_and_upload!(io: uploaded_image, filename: uploaded_image.original_filename)
      #   section["image_url"] = Rails.application.routes.url_helpers.rails_blob_url(image_blob)
      # end
    #   updated_sections << section
    # end

    @page_data.content["sections"] = (params[:sections].values << params[:content][:sections].values).flatten

    if @page_data.save
      redirect_to page_website_path(@website, @page_data.name.underscore), notice: "Page updated successfully."
    else
      render :edit_page, alert: "Failed to update page."
    end
  end

  def preview_page
    @website = Website.find(params[:id])
    @page_data = @website.pages.find { |page| page.name.underscore == params[:page_name].underscore }
  
    if @page_data.nil?
      render plain: "Page not found", status: :not_found
      return
    end

    # Create a temporary page_data object for previewing changes
    preview_page_data = @page_data.dup
    preview_page_data.content["heading"] = params[:heading]
    preview_page_data.content["description"] = params[:description]
    preview_page_data.content["sections"] = (params[:sections].values << params[:content][:sections].values).flatten
  
    # Render the preview content
    render html: render_page(preview_page_data, []).html_safe
  end

  private

  def render_page(page_data, navigation_links)
    template_path = Rails.root.join("app/views/templates/#{page_data['name'].underscore}.liquid")
    common_template_path = Rails.root.join("app/views/templates/common.liquid")

    template_path = File.exist?(template_path) ? template_path : common_template_path
    template = File.read(template_path)
    page_content = Liquid::Template.parse(template).render("content" => page_data["content"], "name" => page_data.name)

    layout_template_path = Rails.root.join("app/views/templates/layout.liquid")
    layout_template = File.read(layout_template_path)
    Liquid::Template.parse(layout_template).render(
      "navigation" => navigation_links,
      "content.heading" => page_data.content["heading"],
      "content_for_page" => page_content
    )
  end
end