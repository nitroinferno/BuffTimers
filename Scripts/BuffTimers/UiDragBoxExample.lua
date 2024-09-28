RestMenu.startDrag = async:callback(function(coord)
    RestMenu.userData.doDrag = true
    RestMenu.userData.lastMousePos = coord.position
  end)

RestMenu.stopDrag = async:callback(function()
    RestMenu.userData.doDrag = false
end)

RestMenu.drag = async:callback(function(coord, layout)
    if not RestMenu.userData.doDrag then return end
    local props = layout.props
    props.position = props.position - (RestMenu.userData.lastMousePos - coord.position)
    I.s3ChimSleep.Menu:update()
    RestMenu.userData.lastMousePos = coord.position
end)

RestMenu.events = {
mousePress = RestMenu.startDrag,
mouseRelease = RestMenu.stopDrag,
mouseMove = RestMenu.drag,
}