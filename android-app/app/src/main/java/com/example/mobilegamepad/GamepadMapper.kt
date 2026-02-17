package com.example.mobilegamepad

import android.view.KeyEvent
import android.view.MotionEvent

object GamepadMapper {
    fun mapAxes(event: MotionEvent): Map<String, Float> {
        return mapOf(
            "left_stick_x" to event.getAxisValue(MotionEvent.AXIS_X),
            "left_stick_y" to event.getAxisValue(MotionEvent.AXIS_Y),
            "right_stick_x" to event.getAxisValue(MotionEvent.AXIS_Z),
            "right_stick_y" to event.getAxisValue(MotionEvent.AXIS_RZ),
            "dpad_x" to event.getAxisValue(MotionEvent.AXIS_HAT_X),
            "dpad_y" to event.getAxisValue(MotionEvent.AXIS_HAT_Y),
            "left_trigger" to event.getAxisValue(MotionEvent.AXIS_BRAKE),
            "right_trigger" to event.getAxisValue(MotionEvent.AXIS_GAS)
        )
    }

    fun mapButton(keyCode: Int): String? {
        return when (keyCode) {
            KeyEvent.KEYCODE_BUTTON_A -> "a"
            KeyEvent.KEYCODE_BUTTON_B -> "b"
            KeyEvent.KEYCODE_BUTTON_X -> "x"
            KeyEvent.KEYCODE_BUTTON_Y -> "y"
            KeyEvent.KEYCODE_BUTTON_L1 -> "lb"
            KeyEvent.KEYCODE_BUTTON_R1 -> "rb"
            KeyEvent.KEYCODE_BUTTON_L2 -> "lt"
            KeyEvent.KEYCODE_BUTTON_R2 -> "rt"
            KeyEvent.KEYCODE_BUTTON_THUMBL -> "ls"
            KeyEvent.KEYCODE_BUTTON_THUMBR -> "rs"
            KeyEvent.KEYCODE_BUTTON_START -> "start"
            KeyEvent.KEYCODE_BUTTON_SELECT -> "back"
            KeyEvent.KEYCODE_BUTTON_MODE -> "home"
            KeyEvent.KEYCODE_DPAD_UP -> "dpad_up"
            KeyEvent.KEYCODE_DPAD_DOWN -> "dpad_down"
            KeyEvent.KEYCODE_DPAD_LEFT -> "dpad_left"
            KeyEvent.KEYCODE_DPAD_RIGHT -> "dpad_right"
            else -> null
        }
    }
}
