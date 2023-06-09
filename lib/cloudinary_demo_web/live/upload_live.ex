defmodule CloudinaryDemoWeb.UploadLive do
  use CloudinaryDemoWeb, :live_view

  defp cloud_name(), do: Application.fetch_env!(:cloudinary_demo, :cloud_name)

  def mount(_params, _session, socket) do
    socket =
      socket
      |> assign(:uploaded_images, [])
      |> allow_upload(:images,
        accept: :any,
        max_entries: 3,
        auto_upload: true,
        external: &presign_upload/2,
        progress: &handle_progress/3
      )

    {:ok, socket}
  end

  defp presign_upload(entry, socket) do
    params = %{
      timestamp: DateTime.utc_now() |> DateTime.to_unix(),
      public_id: entry.client_name,
      eager: "w_400,h_300,c_pad|w_260,h_200,c_crop"
    }

    api_key = Application.fetch_env!(:cloudinary_demo, :api_key)
    api_secret = Application.fetch_env!(:cloudinary_demo, :api_secret)

    query_string_with_secret =
      params
      |> Enum.sort_by(fn {k, _v} -> k end)
      |> Enum.map(fn {k, v} -> "#{k}=#{v}" end)
      |> Enum.join("&")
      |> Kernel.<>(api_secret)

    signature =
      :crypto.hash(:sha, query_string_with_secret)
      |> Base.encode16()
      |> String.downcase()

    fields =
      params
      |> Map.put(:signature, signature)
      |> Map.put(:api_key, api_key)

    meta = %{
      uploader: "Cloudinary",
      url: "http://api.cloudinary.com/v1_1/#{cloud_name()}/image/upload",
      fields: fields
    }

    {:ok, meta, socket}
  end

  def handle_event("validate", _params, socket) do
    {:noreply, socket}
  end

  def handle_event("cancel-upload", %{"ref" => ref}, socket) do
    {:noreply, cancel_upload(socket, :images, ref)}
  end

  defp handle_progress(:images, entry, socket) do
    socket =
      if entry.done? do
        attachment =
          consume_uploaded_entry(socket, entry, fn %{fields: fields} ->
            {:ok, cloudinary_image_url(fields.public_id)}
          end)

        assign(socket, :uploaded_images, [attachment | socket.assigns.uploaded_images])
      else
        socket
      end

    {:noreply, socket}
  end

  def render(assigns) do
    ~H"""
    <h1>Upload images</h1>
    <form phx-change="validate">
      <.live_file_input upload={@uploads.images} />
      <article :for={entry <- @uploads.images.entries} class="upload-entry">
        <figure>
          <.live_img_preview :if={entry.client_type in ["image/png", "image/jpeg"]} entry={entry} />
          <figcaption><%= entry.client_name %></figcaption>
        </figure>

        <button type="button" phx-click="cancel-upload" phx-value-ref={entry.ref} aria-label="cancel">&times;</button>

        <%!-- entry.progress will update automatically for in-flight entries --%>
        <progress value={entry.progress} max="100"><%= entry.progress %>%</progress>

        <div :for={err <- upload_errors(@uploads.images, entry)} class="alert alert-danger">
          <%= upload_error_to_string(err) %>
        </div>
      </article>
    </form>
    <h1 :if={Enum.any?(@uploaded_images)} class="mt-6 mb-2">Uploaded Images</h1>
    <div class="space-y-6">
      <div :for={image_url <- @uploaded_images}>
        <img src={image_url} />
        <%= image_url %>
      </div>
    </div>
    """
  end

  defp cloudinary_image_url(public_id) do
    "https://res.cloudinary.com/#{cloud_name()}/image/upload/w_260,h_200,c_crop/#{public_id}.png"
  end

  defp upload_error_to_string(:too_large), do: "The file is too large"
  defp upload_error_to_string(:too_many_files), do: "You have selected too many files"
  defp upload_error_to_string(:not_accepted), do: "You have selected an unacceptable file type"
  defp upload_error_to_string(:external_client_failure), do: "Something went terribly wrong"
end
