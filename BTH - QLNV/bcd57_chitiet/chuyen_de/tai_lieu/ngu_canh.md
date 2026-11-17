*Ngữ cảnh là thế này:
Bên TDNV sẽ vẫn đẩy 4 bảng liên quan đến tab Chuyên đề như lúc trước, sau đó sẽ có các chỉ số mà bên nifi sẽ cần tự map vào để lấy upsert vào các chỉ số cần trong đó (các bảng liên quan đến task lấy từ db raw). sau đó sẽ cập nhật vào db ở datamart.

Trên app TDNV sẽ bắn 1 api để xem là bên nifi đã thay đổi gì, nifi cần thiết kế ra để  trả lại cho TDNV cập nhật xem các trường mà nifi đã cập nhật vào bảng để  bên TDNV biết được vào cập nhật vào bảng bên đó.

Thế thì ko cần upsert vào luồng cũ nhỉ, tại vì lấy hết 1-1 với bên đó mà.