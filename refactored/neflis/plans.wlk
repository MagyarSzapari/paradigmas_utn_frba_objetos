// =====================================================================
// Neflis - plans
// A plan answers whether it covers the plan a title requires.
// Double dispatch instead of comparing plans or asking for their type:
// the REQUIRED plan tells whether a basic subscription includes it.
// =====================================================================

object basicPlan {
  method covers(requiredPlan) = requiredPlan.isIncludedInBasic()
  method isIncludedInBasic() = true
}

object premiumPlan {
  method covers(requiredPlan) = true
  method isIncludedInBasic() = false
}
