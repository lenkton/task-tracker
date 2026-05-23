module JsonResponse
  def json
    JSON.parse(response.body)
  end
end
