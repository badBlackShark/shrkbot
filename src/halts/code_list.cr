class CodeList
  @@codes = [
    HaltCode.new("T1", "Halt - News Pending", "Trading is halted pending the release of material news."),
    HaltCode.new("T2", "Halt - News Released", "The news has begun the dissemination process through a Regulation FD compliant method(s)."),
    HaltCode.new("T5", "Single Stock Trading Pause in Effect", "Trading has been paused by NASDAQ due to a 10% or more price move in the security in a five-minute period."),
    HaltCode.new("T6", "Halt - Extraordinary Market Activity", "Trading is halted when extraordinary market activity in the security is occurring; NASDAQ determines that such extraordinary market activity is likely to have a material effect on the market for that security; and 1) NASDAQ believes that such extraordinary market activity is caused by the misuse or malfunction of an electronic quotation, communication, reporting or execution system operated by or linked to NASDAQ; or 2) after consultation with either a national securities exchange trading the security on an unlisted trading privileges basis or a non-NASDAQ FINRA facility trading the security, NASDAQ believes such extraordinary market activity is caused by the misuse or malfunction of an electronic quotation, communication, reporting or execution system operated by or linked to such national securities exchange or non- NASDAQ FINRA facility."),
    HaltCode.new("T8", "Halt - Exchange-Traded-Fund (ETF)", "Trading is halted in an ETF due to the consideration of, among other factors: 1) the extent to which trading has ceased in the underlying security(s); 2) whether trading has been halted or suspended in the primary market(s) for any combination of underlying securities accounting for 20% or more of the applicable current index group value; 3) the presence of other unusual conditions or circumstances deemed to be detrimental to the maintenance of a fair and orderly market."),
    HaltCode.new("T12", "Halt - Additional Information Requested by NASDAQ", "Trading is halted pending receipt of additional information requested by NASDAQ."),
    HaltCode.new("H4", "Halt - Non-compliance", "Trading is halted due to the company's non-compliance with NASDAQ listing requirements."),
    HaltCode.new("H9", "Halt - Not Current", "Trading is halted because the company is not current in its required filings."),
    HaltCode.new("H10", "Halt - SEC Trading Suspension", "The Securities and Exchange Commission has suspended trading in this stock."),
    HaltCode.new("H11", "Halt - Regulatory Concern", "Trading is halted in conjunction with another exchange or market for regulatory reasons."),
    HaltCode.new("O1", "Operations Halt, Contact Market Operations"),
    HaltCode.new("IPO1", "HIPO Issue not yet Trading"),
    HaltCode.new("M1", "Corporate Action"),
    HaltCode.new("M2", "Quotation Not Available"),
    HaltCode.new("LUDP", "Volatility Trading Pause"),
    HaltCode.new("LUDS", "Volatility Trading Pause - Straddle Condition"),
    HaltCode.new("MWC1", "Market Wide Circuit Breaker Halt - Level 1"),
    HaltCode.new("MWC2", "Market Wide Circuit Breaker Halt - Level 2"),
    HaltCode.new("MWC3", "Market Wide Circuit Breaker Halt - Level 3"),
    HaltCode.new("MWC0", "Market Wide Circuit Breaker Halt - Carry over from previous day"),
    HaltCode.new("T3", "News and Resumption Times", "The news has been fully disseminated through a Regulation FD compliant method(s); or NASDAQ has determined either that system misuse or malfunction that caused extraordinary market activity will no longer have a material effect on the market for the security or that system misuse or malfunction is not the cause of the extraordinary market activity; or NASDAQ has determined the conditions which led to a halt in an Exchange-Traded Fund are no longer present. Two times will be displayed: (1) the time when market participants can enter quotations, followed by (2) the time the security will be released for trading. All trade halt and resumption times will be posted in HH:MM:SS format."),
    HaltCode.new("T7", "Single Stock Trading Pause/Quotation-Only Period", "Quotations have resumed for affected security, but trading remains paused."),
    HaltCode.new("R4", "Qualifications Issues Reviewed/Resolved; Quotations/Trading to Resume"),
    HaltCode.new("R9", "Filing Requirements Satisfied/Resolved; Quotations/Trading To Resume"),
    HaltCode.new("C3", "Issuer News Not Forthcoming; Quotations/Trading To Resume"),
    HaltCode.new("C4", "Qualifications Halt ended; maint. req. met; Resume"),
    HaltCode.new("C9", "Qualifications Halt Concluded; Filings Met; Quotes/Trades To Resume"),
    HaltCode.new("C11", "Trade Halt Concluded By Other Regulatory Auth,; Quotes/Trades Resume"),
    HaltCode.new("R1", "New Issue Available"),
    HaltCode.new("R2", "Issue Available"),
    HaltCode.new("IPOQ", "IPO security released for quotation"),
    HaltCode.new("IPOE", "IPO security - positioning window extension"),
    HaltCode.new("MWCQ", "Market Wide Circuit Breaker Resumption"),
    HaltCode.new("M", "Volatility Trading Pause", "Trading has been paused in an Exchange-Listed issue (Market Category Code = C)"),
    HaltCode.new("D", "Security deletion from NASDAQ / CQS"),
    HaltCode.new("Space", "Reason Not Available"),
  ]

  def self.find_code(code : String) : HaltCode
    @@codes.find { |hc| hc.symbol.downcase == code.downcase } || HaltCode.new("ERROR", "Couldn't find this code. Code provided was *#{code}*.")
  end
end
