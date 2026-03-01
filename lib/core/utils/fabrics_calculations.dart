class FabricsCalculations {
  /// Calculates the quantity of yarn in a fabric given the total quantity and lycra percentage.
  /// Equation: Yarn Qty = Total Qty * (1 - (Lycra% / 100))
  static double calculateYarnQuantity({
    required double totalQuantity,
    required double lycraPercentage,
  }) {
    double lycraDecimal = lycraPercentage / 100;
    return totalQuantity * (1 - lycraDecimal);
  }

  /// Calculates the quantity of lycra in a fabric given the total quantity and lycra percentage.
  /// Equation: Lycra Qty = Total Qty * (Lycra% / 100)
  static double calculateLycraQuantity({
    required double totalQuantity,
    required double lycraPercentage,
  }) {
    double lycraDecimal = lycraPercentage / 100;
    return totalQuantity * lycraDecimal;
  }

  /// Calculates the value of yarn in an item.
  /// Equation: Yarn Value = (Total Qty * (1 - Lycra%)) * Yarn Price
  static double calculateItemYarnValue({
    required double quantity,
    required double lycraPercentage,
    required double yarnPrice,
  }) {
    double yarnQty = calculateYarnQuantity(
      totalQuantity: quantity,
      lycraPercentage: lycraPercentage,
    );
    return yarnQty * yarnPrice;
  }

  /// Calculates the base value of a single item based on its type and global prices.
  /// 
  /// Logic:
  /// - If Fabric (قماش): (YarnQty * YarnPrice) + (LycraQty * LycraPrice) + (TotalQty * MfgPrice)
  /// - If CM: (LycraQty * LycraPrice) + (TotalQty * MfgPrice)
  /// - If Other: TotalQty * MfgPrice
  static double calculateItemBaseValue({
    required double quantity,
    required double lycraPercentage,
    required bool isFabric,
    required bool isCm,
    required double yarnPrice,
    required double lycraPrice,
    required double manufacturingPrice,
  }) {
    double lycraDecimal = lycraPercentage / 100;
    
    if (isFabric) {
      double yarnQty = quantity * (1 - lycraDecimal);
      double lycraQty = quantity * lycraDecimal;
      return (yarnQty * yarnPrice) + (lycraQty * lycraPrice) + (manufacturingPrice * quantity);
    } else if (isCm) {
      double lycraQty = quantity * lycraDecimal;
      return (lycraQty * lycraPrice) + (manufacturingPrice * quantity);
    } else {
      return quantity * manufacturingPrice;
    }
  }

  /// Calculates the waste for an item.
  /// Equation: Waste = Yarn Value * 2% (only applied to Fabrics)
  static double calculateItemWaste({
    required double yarnValue,
    required bool isFabric,
  }) {
    if (isFabric) {
      return yarnValue * 0.02;
    }
    return 0.0;
  }

  /// Calculates the final total value (Base + Waste).
  static double calculateItemTotalValue({
    required double baseValue,
    required double wasteValue,
  }) {
    return baseValue + wasteValue;
  }
}
