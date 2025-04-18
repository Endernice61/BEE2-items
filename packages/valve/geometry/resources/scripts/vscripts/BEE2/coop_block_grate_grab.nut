// Block +USE and therefore pickup if the player is on the other side of grating.
block_grab_holder <- null;

function OnPostSpawn() {
	self.ConnectOutput("OnPlayerPickup", "BlockGrabPickup");
	self.ConnectOutput("OnPhysGunDrop", "BlockGrabDrop");
}

function InputUse() {
	local player = activator;
	local trace;
	if (player.GetClassname() != "player") {
		return true; // ??
	}
	if (block_grab_holder == player) {
		return true; // Always allow drop.
	}

	local success;
	local portals = ::BEE_GetPortalPairs();

	local player_pos = player.EyePosition();

	local other_player = null;
	if (block_grab_holder != null) {
		// We're held, The other player could pushing the cube through grating,
		// check they're holding it validly.
		local other_player = block_grab_holder.EyePosition();
		if (!BlockGrabCubeCheck(other_player)) {
			// Try through portals.
			success = false;
			foreach (pair in portals) {
				// Move out a tad so we don't trace exactly on a surface.
				local left = pair[0].GetOrigin() + pair[0].GetForwardVector();
				local right = pair[1].GetOrigin() + pair[1].GetForwardVector();
				if (BlockGrabCubeCheck(left) && BlockGrabCheck(right, other_player)) {
					success = true;
					break
				}
				if (BlockGrabCheck(other_player, left) && BlockGrabCubeCheck(right)) {
					success = true;
					break
				}
			}
			if (!success) {
				// Holding player is illegally holding, fail.
				return false;
			}
		}
	}
	if (BlockGrabCubeCheck(player_pos)) {
		// Direct grab, we're good.
		return true;
	}
	foreach (pair in portals) {
		local left = pair[0].GetOrigin() + pair[0].GetForwardVector();
		local right = pair[1].GetOrigin() + pair[1].GetForwardVector();
		if (BlockGrabCubeCheck(left) && BlockGrabCheck(right, player_pos)) {
			return true;
		}
		if (BlockGrabCheck(player_pos, left) && BlockGrabCubeCheck(right)) {
			return true;
		}
	}
	return false;
}

// Check if there is a path to the cube.
// We check the center plus the three closest faces.
function BlockGrabCubeCheck(pos) {
	local cube_pos = self.GetOrigin();
	if (BlockGrabCheck(pos, cube_pos)) {
		return true;
	}
	local offset = self.GetOrigin() - pos;
	foreach (axis in [
		self.GetForwardVector(),
		self.GetLeftVector(),
		self.GetUpVector(),
	]) {
		local targ;
		if (offset.Dot(axis) > 0) {
			targ = cube_pos + axis * -18;
		} else {
			targ = cube_pos + axis * 18;
		}
		if (BlockGrabCheck(pos, targ)) {
			return true;
		}
	}
	return false;
}

// Check if this path is sufficently free.
function BlockGrabCheck(start, end) {
	// Don't allow long ranges. PLAYER_USE_RADIUS = 80 from sdk-2013.
	// Add a little to account for cube radius.
	if ((start - end).LengthSqr() > (110 * 110)) {
		return false;
	}
	local result;
	if (TraceLine(start, end, null) != 1.0) {
		result = false;
	} else {
		result = ::BEE_TraceRay(start, end-start, ::BEECollide.GRATING) == null;
	}
	// DebugDrawLine(start, end, result ? 0 : 255, result ? 255 : 0, 0, true, 2.5);
	return result;
}

function BlockGrabPickup() {
	block_grab_holder = activator;
}

function BlockGrabDrop() {
	block_grab_holder = null;
}
