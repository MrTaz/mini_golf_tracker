package org.dahome.mini_golf_tracker

import org.junit.Rule
import org.junit.runner.RunWith
import pl.leancode.patrol.PatrolTestRule
import pl.leancode.patrol.PatrolTestRunner

@RunWith(PatrolTestRunner::class)
class MainActivityTest {
    @get:Rule
    val rule = PatrolTestRule(MainActivity::class.java)
}
