/**
 * Calculate simple interest and total payable.
 * SI = (Principal × Rate × Time) / 100
 */
const calculateLoanDetails = (principal, ratePercent, durationMonths) => {
    const interest = (principal * ratePercent * durationMonths) / 100;
    const total = principal + interest;
    return {
        interest_amount: parseFloat(interest.toFixed(2)),
        total_payable: parseFloat(total.toFixed(2)),
        remaining_balance: parseFloat(total.toFixed(2)),
    };
};

/**
 * Split a repayment amount into principal and interest portions
 * proportional to the remaining balances.
 */
const splitRepayment = (amount, remainingPrincipal, remainingInterest) => {
    const total = remainingPrincipal + remainingInterest;
    if (total <= 0) return { principal_portion: 0, interest_portion: 0 };

    const interestPortion = parseFloat(Math.min(amount * (remainingInterest / total), remainingInterest).toFixed(2));
    const principalPortion = parseFloat(Math.min(amount - interestPortion, remainingPrincipal).toFixed(2));

    return { principal_portion: principalPortion, interest_portion: interestPortion };
};

/**
 * Calculate dynamic real-time interest based on elapsed time.
 */
const calculateDynamicLoanDetails = (loan, monthsOverride = null) => {
    if (loan.status === 'pending' || loan.status === 'rejected' || !loan.approved_at) {
        return {
            dynamic_interest_amount: 0,
            dynamic_total_payable: loan.principal,
            dynamic_remaining_balance: loan.principal,
            monthsElapsed: 0,
        };
    }

    let monthsElapsed;
    if (monthsOverride !== null && monthsOverride !== undefined) {
        monthsElapsed = monthsOverride;
    } else {
        const msIn30Days = 30 * 24 * 60 * 60 * 1000;
        const diff = new Date() - new Date(loan.approved_at);
        monthsElapsed = Math.max(1, Math.ceil(diff / msIn30Days));
    }

    const principal = parseFloat(loan.principal);
    const interestRate = parseFloat(loan.interest_rate);

    const dynamic_interest_amount = parseFloat(((principal * interestRate * monthsElapsed) / 100).toFixed(2));
    const dynamic_total_payable = parseFloat((principal + dynamic_interest_amount).toFixed(2));

    // We need to know how much they ALREADY paid to find dynamic remaining balance.
    // Total original payable - remaining = amount paid so far.
    const amountPaidSoFar = parseFloat(loan.total_payable) - parseFloat(loan.remaining_balance);
    const dynamic_remaining_balance = Math.max(0, parseFloat((dynamic_total_payable - amountPaidSoFar).toFixed(2)));

    return {
        dynamic_interest_amount,
        dynamic_total_payable,
        dynamic_remaining_balance,
        monthsElapsed
    };
};

module.exports = { calculateLoanDetails, splitRepayment, calculateDynamicLoanDetails };
