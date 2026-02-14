import argparse
import csv
import math
from dataclasses import dataclass


@dataclass
class PairResult:
    pair: int
    y0_r: int
    y0_i: int
    y1_r: int
    y1_i: int


def read_pair_results(csv_path: str):
    rows = []
    with open(csv_path, "r", newline="") as f:
        reader = csv.DictReader(f)
        for row in reader:
            rows.append(
                PairResult(
                    pair=int(row["pair"]),
                    y0_r=int(row["y0_r"]),
                    y0_i=int(row["y0_i"]),
                    y1_r=int(row["y1_r"]),
                    y1_i=int(row["y1_i"]),
                )
            )
    return rows


def expected_for_pair(pair_idx: int):
    x0 = 2 * pair_idx
    x1 = 2 * pair_idx + 1

    y0_r_exp = x0 + x1
    y1_r_exp = x0 - x1

    y0_i_exp = 0
    y1_i_exp = 0
    return y0_r_exp, y0_i_exp, y1_r_exp, y1_i_exp


def run_check(csv_path: str, lsb_tolerance: int):
    results = read_pair_results(csv_path)
    if not results:
        raise RuntimeError("CSV kosong, tidak ada hasil pair dari RTL.")

    abs_errors = []
    max_abs_err = 0
    fail_count = 0
    mismatches = []

    for row in results:
        y0_r_exp, y0_i_exp, y1_r_exp, y1_i_exp = expected_for_pair(row.pair)

        errs = [
            abs(row.y0_r - y0_r_exp),
            abs(row.y0_i - y0_i_exp),
            abs(row.y1_r - y1_r_exp),
            abs(row.y1_i - y1_i_exp),
        ]

        row_max = max(errs)
        max_abs_err = max(max_abs_err, row_max)
        abs_errors.extend(errs)

        if row_max > lsb_tolerance:
            fail_count += 1
            mismatches.append(
                {
                    "pair": row.pair,
                    "exp": (y0_r_exp, y0_i_exp, y1_r_exp, y1_i_exp),
                    "got": (row.y0_r, row.y0_i, row.y1_r, row.y1_i),
                    "row_max_err": row_max,
                }
            )

    mse = sum(e * e for e in abs_errors) / len(abs_errors)
    rmse = math.sqrt(mse)

    passed = fail_count == 0
    return {
        "passed": passed,
        "pairs_checked": len(results),
        "max_abs_err": max_abs_err,
        "mse": mse,
        "rmse": rmse,
        "fail_count": fail_count,
        "mismatches": mismatches,
    }


def main():
    parser = argparse.ArgumentParser(
        description="Checker output Top_FFT hold2 vs expected software model"
    )
    parser.add_argument(
        "--csv",
        default="top_fft_pair_results.csv",
        help="Path CSV hasil dump testbench",
    )
    parser.add_argument(
        "--tol",
        type=int,
        default=2,
        help="Toleransi dalam LSB",
    )

    args = parser.parse_args()

    report = run_check(args.csv, args.tol)

    print("=== Top_FFT Software Check ===")
    print(f"pairs_checked : {report['pairs_checked']}")
    print(f"max_abs_err   : {report['max_abs_err']} LSB")
    print(f"mse           : {report['mse']:.3f}")
    print(f"rmse          : {report['rmse']:.3f}")
    print(f"fail_count    : {report['fail_count']}")
    print(f"status        : {'PASS' if report['passed'] else 'FAIL'}")

    if report["mismatches"]:
        print("first_mismatches:")
        for mm in report["mismatches"][:5]:
            print(
                f"  pair={mm['pair']} exp={mm['exp']} got={mm['got']} max_err={mm['row_max_err']}"
            )

    raise SystemExit(0 if report["passed"] else 1)


if __name__ == "__main__":
    main()
