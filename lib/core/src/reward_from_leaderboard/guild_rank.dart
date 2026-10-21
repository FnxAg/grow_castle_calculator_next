int getItemBoxFromGuildRank(int rank) {
  return switch (rank) {
    1 => 20, 
    2 => 15,
    3 => 10,
    >= 4 && <= 5 => 7,
    >= 6 && <= 10 => 5,
    >= 11 && <= 50 => 3,
    >= 51 && <= 100 => 1,
    _ => 0,
  };
}